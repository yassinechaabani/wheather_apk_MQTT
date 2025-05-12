import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:station_meteo/models/weather_data.dart';

class SensorSimulatorService {
  final Random _random = Random();
  Timer? _simulationTimer;

  // Callback pour les données simulées
  Function(WeatherData)? onSimulatedDataReceived;

  // État de la simulation
  bool _isSimulating = false;
  bool get isSimulating => _isSimulating;

  // Intervalle de simulation en secondes
  int _simulationInterval = 10;
  int get simulationInterval => _simulationInterval;
  set simulationInterval(int value) {
    if (value >= 1 && value <= 60) {
      _simulationInterval = value;
      if (_isSimulating) {
        // Redémarrer la simulation avec le nouvel intervalle
        stopSimulation();
        startSimulation();
      }
    }
  }

  // Liste des capteurs à simuler
  final List<String> _sensorsToSimulate = [
    'dht22',
    'bmp280',
    'anemometer',
    'soil_moisture',
    'light_sensor',
    'rain_gauge',
  ];

  // Démarrer la simulation
  void startSimulation() {
    if (_isSimulating) return;

    _isSimulating = true;

    // Générer des données immédiatement
    _generateAndSendData();

    // Configurer le timer pour générer des données périodiquement
    _simulationTimer = Timer.periodic(
      Duration(seconds: _simulationInterval),
      (_) => _generateAndSendData(),
    );

    debugPrint(
        'Simulation démarrée avec un intervalle de $_simulationInterval secondes');
  }

  // Arrêter la simulation
  void stopSimulation() {
    if (!_isSimulating) return;

    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isSimulating = false;

    debugPrint('Simulation arrêtée');
  }

  // Générer et envoyer des données simulées
  void _generateAndSendData() {
    final sensorData = <String, dynamic>{};

    // Simuler les données pour chaque capteur
    for (final sensor in _sensorsToSimulate) {
      switch (sensor) {
        case 'dht11':
        case 'dht22':
          sensorData[sensor] = {
            'temperature': 20 + _random.nextDouble() * 15,
            'humidity': 30 + _random.nextDouble() * 60,
          };
          break;
        case 'bmp280':
          sensorData[sensor] = {
            'temperature': 20 + _random.nextDouble() * 15,
            'pressure': 1000 + _random.nextDouble() * 30,
            'altitude': 100 + _random.nextDouble() * 50,
          };
          break;
        case 'anemometer':
          sensorData[sensor] = {
            'speed': _random.nextDouble() * 30,
            'direction': _random.nextDouble() * 360,
          };
          break;
        case 'soil_moisture':
          sensorData[sensor] = {
            'value': _random.nextDouble() * 100,
          };
          break;
        case 'light_sensor':
          sensorData[sensor] = {
            'value': _random.nextDouble() * 2000,
          };
          break;
        case 'rain_gauge':
          sensorData[sensor] = {
            'value': _random.nextDouble() * 10,
          };
          break;
      }
    }

    // Créer un objet WeatherData à partir des données simulées
    final weatherData = WeatherData.fromSensorData(sensorData);

    // Appeler le callback si défini
    if (onSimulatedDataReceived != null) {
      onSimulatedDataReceived!(weatherData);
    }

    debugPrint('Données simulées générées: ${sensorData.keys.join(', ')}');
  }

  // Configurer les capteurs à simuler
  void configureSensorsToSimulate(List<String> sensors) {
    _sensorsToSimulate.clear();
    _sensorsToSimulate.addAll(sensors);

    debugPrint(
        'Capteurs configurés pour la simulation: ${_sensorsToSimulate.join(', ')}');
  }

  // Disposer le service
  void dispose() {
    stopSimulation();
  }
}
