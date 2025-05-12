import 'package:flutter/material.dart';
import 'package:station_meteo/models/weather_data.dart';
import 'package:station_meteo/widgets/animated_weather_card.dart';

class SensorDataCard extends StatelessWidget {
  final WeatherData weatherData;

  const SensorDataCard({
    Key? key,
    required this.weatherData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sensors = weatherData.getAvailableSensors();

    if (sensors.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedWeatherCard(
      title: 'Données des Capteurs',
      icon: Icons.sensors,
      color: Colors.indigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...sensors.map((sensor) => _buildSensorSection(sensor)),
        ],
      ),
    );
  }

  Widget _buildSensorSection(String sensorType) {
    final sensorData = weatherData.sensorData[sensorType];
    if (sensorData == null) return const SizedBox.shrink();

    IconData sensorIcon;
    Color sensorColor;
    String sensorName;

    switch (sensorType) {
      case 'dht11':
        sensorIcon = Icons.thermostat;
        sensorColor = Colors.red;
        sensorName = 'DHT11';
        break;
      case 'dht22':
        sensorIcon = Icons.thermostat;
        sensorColor = Colors.orange;
        sensorName = 'DHT22';
        break;
      case 'bmp280':
        sensorIcon = Icons.compress;
        sensorColor = Colors.blue;
        sensorName = 'BMP280';
        break;
      case 'anemometer':
        sensorIcon = Icons.air;
        sensorColor = Colors.teal;
        sensorName = 'Anémomètre';
        break;
      case 'soil_moisture':
        sensorIcon = Icons.water_drop;
        sensorColor = Colors.brown;
        sensorName = 'Humidité du Sol';
        break;
      case 'light_sensor':
        sensorIcon = Icons.wb_sunny;
        sensorColor = Colors.amber;
        sensorName = 'Capteur de Lumière';
        break;
      case 'rain_gauge':
        sensorIcon = Icons.umbrella;
        sensorColor = Colors.lightBlue;
        sensorName = 'Pluviomètre';
        break;
      default:
        sensorIcon = Icons.device_unknown;
        sensorColor = Colors.grey;
        sensorName = sensorType.toUpperCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sensorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sensorColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(sensorIcon, color: sensorColor, size: 20),
              const SizedBox(width: 8),
              Text(
                sensorName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: sensorColor,
                ),
              ),
            ],
          ),
        ),
        ...sensorData.entries.map(
            (entry) => _buildSensorValue(entry.key, entry.value, sensorColor)),
        const Divider(),
      ],
    );
  }

  Widget _buildSensorValue(String key, dynamic value, Color color) {
    // Ignorer les champs spéciaux ou les objets complexes
    if (value is Map || value is List || key == 'id' || key == 'type') {
      return const SizedBox.shrink();
    }

    String displayKey = _formatKey(key);
    String displayValue = _formatValue(key, value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayKey,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    // Convertir snake_case ou camelCase en texte lisible
    final words = key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .split('_')
        .join(' ')
        .split(' ');

    // Capitaliser chaque mot
    final formattedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    return formattedWords;
  }

  String _formatValue(String key, dynamic value) {
    if (value is num) {
      // Formater selon le type de donnée
      if (key.contains('temp')) {
        return '${value.toStringAsFixed(1)} °C';
      } else if (key.contains('humid')) {
        return '${value.toStringAsFixed(1)} %';
      } else if (key.contains('pressure')) {
        return '${value.toStringAsFixed(1)} hPa';
      } else if (key.contains('altitude')) {
        return '${value.toStringAsFixed(1)} m';
      } else if (key.contains('speed') || key.contains('wind')) {
        return '${value.toStringAsFixed(1)} km/h';
      } else if (key.contains('rain') || key.contains('precipitation')) {
        return '${value.toStringAsFixed(1)} mm';
      } else if (key.contains('light') || key.contains('lux')) {
        return '${value.toStringAsFixed(1)} lux';
      } else if (key.contains('soil') || key.contains('moisture')) {
        return '${value.toStringAsFixed(1)} %';
      } else {
        return value.toString();
      }
    }

    return value.toString();
  }
}
