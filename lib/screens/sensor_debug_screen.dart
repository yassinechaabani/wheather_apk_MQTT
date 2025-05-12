import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_meteo/providers/weather_providers.dart';
import 'package:station_meteo/models/weather_data.dart';
import 'package:station_meteo/widgets/animated_weather_card.dart';

class SensorDebugScreen extends StatefulWidget {
  const SensorDebugScreen({Key? key}) : super(key: key);

  @override
  State<SensorDebugScreen> createState() => _SensorDebugScreenState();
}

class _SensorDebugScreenState extends State<SensorDebugScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bug_report),
            SizedBox(width: 8),
            Text('Débogage des Capteurs'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          final currentWeather = weatherProvider.currentWeather;

          if (currentWeather == null) {
            return const Center(
              child: Text('Aucune donnée disponible'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedWeatherCard(
                  title: 'Données Brutes des Capteurs',
                  icon: Icons.code,
                  color: Colors.purple,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dernière mise à jour: ${_formatDateTime(currentWeather.timestamp)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRawDataView(currentWeather),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedWeatherCard(
                  title: 'Capteurs Détectés',
                  icon: Icons.sensors,
                  color: Colors.teal,
                  child: _buildSensorList(currentWeather),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRawDataView(WeatherData data) {
    final jsonData = data.toJson();
    final prettyJson = _prettyPrintJson(jsonData);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          prettyJson,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildSensorList(WeatherData data) {
    final sensors = data.getAvailableSensors();

    if (sensors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Aucun capteur détecté'),
      );
    }

    return Column(
      children: sensors.map((sensor) {
        IconData sensorIcon;
        Color sensorColor;

        switch (sensor) {
          case 'dht11':
            sensorIcon = Icons.thermostat;
            sensorColor = Colors.red;
            break;
          case 'dht22':
            sensorIcon = Icons.thermostat;
            sensorColor = Colors.orange;
            break;
          case 'bmp280':
            sensorIcon = Icons.compress;
            sensorColor = Colors.blue;
            break;
          case 'anemometer':
            sensorIcon = Icons.air;
            sensorColor = Colors.teal;
            break;
          case 'soil_moisture':
            sensorIcon = Icons.water_drop;
            sensorColor = Colors.brown;
            break;
          case 'light_sensor':
            sensorIcon = Icons.wb_sunny;
            sensorColor = Colors.amber;
            break;
          case 'rain_gauge':
            sensorIcon = Icons.umbrella;
            sensorColor = Colors.lightBlue;
            break;
          default:
            sensorIcon = Icons.device_unknown;
            sensorColor = Colors.grey;
        }

        return ListTile(
          leading: Icon(sensorIcon, color: sensorColor),
          title: Text(
            _formatSensorName(sensor),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: sensorColor,
            ),
          ),
          subtitle: Text('Données disponibles'),
          trailing: Icon(Icons.check_circle, color: Colors.green),
        );
      }).toList(),
    );
  }

  String _formatSensorName(String sensorId) {
    switch (sensorId) {
      case 'dht11':
        return 'DHT11 (Température/Humidité)';
      case 'dht22':
        return 'DHT22 (Température/Humidité)';
      case 'bmp280':
        return 'BMP280 (Pression/Altitude)';
      case 'anemometer':
        return 'Anémomètre (Vent)';
      case 'soil_moisture':
        return 'Capteur d\'humidité du sol';
      case 'light_sensor':
        return 'Capteur de lumière';
      case 'rain_gauge':
        return 'Pluviomètre';
      default:
        return sensorId.toUpperCase();
    }
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    String result = '{\n';

    json.forEach((key, value) {
      result += '  "$key": ';

      if (value is Map) {
        result += '{\n';
        (value as Map).forEach((k, v) {
          result += '    "$k": $v,\n';
        });
        result += '  },\n';
      } else if (value is List) {
        result += '[\n';
        for (var item in value) {
          result += '    $item,\n';
        }
        result += '  ],\n';
      } else {
        result += '$value,\n';
      }
    });

    result += '}';
    return result;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
