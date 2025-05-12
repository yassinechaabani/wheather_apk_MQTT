import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_meteo/models/weather_data.dart';

class MqttService {
  MqttServerClient? _client;
  final String _clientId =
      'flutter_weather_station_${DateTime.now().millisecondsSinceEpoch}';

  String _host = 'broker.hivemq.com';
  int _port = 1883;
  String _username = '';
  String _password = '';
  String _topic = 'weather/data';
  bool _useSSL = false;

  Function(WeatherData)? onWeatherDataReceived;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  Future<void> initialize() async {
    await _loadSettings();
    await connect();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _host = prefs.getString('mqtt_host') ?? 'broker.hivemq.com';
      _port = prefs.getInt('mqtt_port') ?? 1883;
      _username = prefs.getString('mqtt_username') ?? '';
      _password = prefs.getString('mqtt_password') ?? '';
      _topic = prefs.getString('mqtt_topic') ?? 'weather/data';
      _useSSL = prefs.getBool('mqtt_use_ssl') ?? false;
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres MQTT: $e');
    }
  }

  Future<void> saveSettings({
    required String host,
    required int port,
    required String username,
    required String password,
    required String topic,
    required bool useSSL,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mqtt_host', host);
      await prefs.setInt('mqtt_port', port);
      await prefs.setString('mqtt_username', username);
      await prefs.setString('mqtt_password', password);
      await prefs.setString('mqtt_topic', topic);
      await prefs.setBool('mqtt_use_ssl', useSSL);

      _host = host;
      _port = port;
      _username = username;
      _password = password;
      _topic = topic;
      _useSSL = useSSL;

      await disconnect();
      await connect();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des paramètres MQTT: $e');
      rethrow;
    }
  }

  Future<bool> connect() async {
    _connectionStatusController.add(ConnectionStatus.connecting);

    if (_client != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      _isConnected = true;
      _connectionStatusController.add(ConnectionStatus.connected);
      return true;
    }

    try {
      _client = MqttServerClient(_host, _clientId, maxConnectionAttempts: 3);
      _client!.port = _port;
      _client!.keepAlivePeriod = 60;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;

      if (_useSSL) {
        _client!.secure = true;
        _client!.securityContext = SecurityContext.defaultContext;
      }

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(_clientId)
          .withWillTopic('willtopic')
          .withWillMessage('Déconnexion inattendue')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      if (_username.isNotEmpty) {
        connMessage.authenticateAs(_username, _password);
      }

      _client!.connectionMessage = connMessage;

      await _client!.connect();

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('MQTT Client connecté');
        _isConnected = true;
        _connectionStatusController.add(ConnectionStatus.connected);

        _client!.subscribe(_topic, MqttQos.atLeastOnce);
        _client!.subscribe('$_topic/dht11', MqttQos.atLeastOnce);
        _client!.subscribe('$_topic/dht22', MqttQos.atLeastOnce);
        _client!.subscribe('$_topic/bmp280', MqttQos.atLeastOnce);
        _client!.subscribe('$_topic/anemometer', MqttQos.atLeastOnce);
        _client!.subscribe('$_topic/soil', MqttQos.atLeastOnce);
        _client!.subscribe('$_topic/light', MqttQos.atLeastOnce);
        _client!.subscribe('$_topic/rain', MqttQos.atLeastOnce);

        _client!.updates!.listen(_onMessage);

        return true;
      } else {
        debugPrint('MQTT Client non connecté');
        _isConnected = false;
        _connectionStatusController.add(ConnectionStatus.failed);
        return false;
      }
    } catch (e) {
      debugPrint('Exception lors de la connexion MQTT: $e');
      _isConnected = false;
      _connectionStatusController.add(ConnectionStatus.failed);
      return false;
    }
  }

  void _onConnected() {
    debugPrint('MQTT Client connecté');
    _isConnected = true;
    _connectionStatusController.add(ConnectionStatus.connected);
  }

  void _onDisconnected() {
    debugPrint('MQTT Client déconnecté');
    _isConnected = false;
    _connectionStatusController.add(ConnectionStatus.disconnected);
  }

  void _onSubscribed(String topic) {
    debugPrint('Abonnement confirmé pour le topic: $topic');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (var message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      debugPrint('Message reçu: $payload du topic: ${message.topic}');

      try {
        final dynamic rawData = json.decode(payload);

        if (rawData is Map<String, dynamic>) {
          final data = rawData;
          WeatherData weatherData;

          if (message.topic.contains('/')) {
            final sensorType = message.topic.split('/').last;
            final Map<String, dynamic> sensorData = {sensorType: data};
            weatherData = WeatherData.fromSensorData(sensorData);
            onWeatherDataReceived?.call(weatherData);
          } else if (data.containsKey('sensors')) {
            weatherData = WeatherData.fromSensorData(data['sensors']);
            onWeatherDataReceived?.call(weatherData);
          } else if (data.containsKey('dht11') ||
              data.containsKey('dht22') ||
              data.containsKey('bmp280') ||
              data.containsKey('anemometer')) {
            weatherData = WeatherData.fromSensorData(data);
            onWeatherDataReceived?.call(weatherData);
          } else {
            weatherData = WeatherData(
              temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
              humidity: (data['humidity'] as num?)?.toDouble() ?? 0,
              windSpeed: (data['windSpeed'] as num?)?.toDouble() ?? 0,
              timestamp: DateTime.now(),
              sensorData: data['sensorData'] ?? {},
            );
            onWeatherDataReceived?.call(weatherData);
          }
        } else {
          debugPrint(
              'Le message reçu n\'est pas un Map<String, dynamic>: $rawData');
        }
      } catch (e) {
        debugPrint('Erreur lors du traitement du message: $e');
      }
    }
  }

  Future<void> publishMessage(String topic, String message) async {
    if (_client != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } else {
      throw Exception('Client non connecté');
    }
  }

  Future<void> disconnect() async {
    if (_client != null) {
      _client!.disconnect();
      _isConnected = false;
      _connectionStatusController.add(ConnectionStatus.disconnected);
    }
  }

  Future<Map<String, dynamic>> getConnectionSettings() async {
    return {
      'host': _host,
      'port': _port,
      'username': _username,
      'password': _password,
      'topic': _topic,
      'useSSL': _useSSL,
    };
  }

  Future<bool> testConnection({
    required String host,
    required int port,
    required String username,
    required String password,
    required bool useSSL,
  }) async {
    final testClient =
        MqttServerClient(host, '${_clientId}_test', maxConnectionAttempts: 1);
    testClient.port = port;
    testClient.keepAlivePeriod = 20;

    if (useSSL) {
      testClient.secure = true;
      testClient.securityContext = SecurityContext.defaultContext;
    }

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('${_clientId}_test')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (username.isNotEmpty) {
      connMessage.authenticateAs(username, password);
    }

    testClient.connectionMessage = connMessage;

    try {
      await testClient.connect();
      if (testClient.connectionStatus!.state == MqttConnectionState.connected) {
        testClient.disconnect();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors du test de connexion: $e');
      return false;
    }
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}

enum ConnectionStatus { disconnected, connecting, connected, failed }
