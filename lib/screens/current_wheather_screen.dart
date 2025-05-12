import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_meteo/providers/weather_providers.dart';
import 'package:station_meteo/widgets/weather_gauge.dart';
import 'package:station_meteo/widgets/animated_weather_card.dart';
import 'package:station_meteo/widgets/safe_lottie_animation.dart';
import 'package:station_meteo/utils/animation_utils.dart';
import 'package:station_meteo/widgets/sensor_data_card.dart';

class CurrentWeatherScreen extends StatefulWidget {
  const CurrentWeatherScreen({Key? key}) : super(key: key);

  @override
  State<CurrentWeatherScreen> createState() => _CurrentWeatherScreenState();
}

class _CurrentWeatherScreenState extends State<CurrentWeatherScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        final currentWeather = weatherProvider.currentWeather;

        if (currentWeather == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(height: 16),
                Text(
                  'En attente des données météo...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        final weatherCondition = AnimationUtils.getWeatherCondition(
          currentWeather.temperature,
          currentWeather.humidity,
          currentWeather.windSpeed,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(),

              // Carte des données actuelles
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                )),
                child: AnimatedWeatherCard(
                  title: 'Données Actuelles',
                  icon: Icons.cloud,
                  color: Colors.blue,
                  child: Column(
                    children: [
                      // Nouvelle ligne mise à jour avec le temps écoulé
                      Consumer<WeatherProvider>(
                        builder: (context, provider, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.update,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _getLastUpdateText(provider.lastUpdateTime),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          WeatherGauge(
                            value: currentWeather.temperature,
                            title: 'Température',
                            unit: '°C',
                            minValue: -10,
                            maxValue: 50,
                            icon: Icons.thermostat,
                            color: Colors.red,
                          ),
                          WeatherGauge(
                            value: currentWeather.humidity,
                            title: 'Humidité',
                            unit: '%',
                            minValue: 0,
                            maxValue: 100,
                            icon: Icons.water_drop,
                            color: Colors.blue,
                          ),
                          WeatherGauge(
                            value: currentWeather.windSpeed,
                            title: 'Vent',
                            unit: 'km/h',
                            minValue: 0,
                            maxValue: 150,
                            icon: Icons.air,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                )),
                child: SensorDataCard(weatherData: currentWeather),
              ),

              const SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                )),
                child: AnimatedWeatherCard(
                  title: 'Détails',
                  icon: Icons.info_outline,
                  color: Colors.purple,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                          Icons.thermostat,
                          'Température',
                          '${currentWeather.temperature.toStringAsFixed(1)} °C',
                          Colors.red),
                      const Divider(),
                      _buildDetailRow(
                          Icons.water_drop,
                          'Humidité',
                          '${currentWeather.humidity.toStringAsFixed(1)} %',
                          Colors.blue),
                      const Divider(),
                      _buildDetailRow(
                          Icons.air,
                          'Vent',
                          '${currentWeather.windSpeed.toStringAsFixed(1)} km/h',
                          Colors.green),
                      if (currentWeather.getPressure() != null) ...[
                        const Divider(),
                        _buildDetailRow(
                            Icons.compress,
                            'Pression',
                            '${currentWeather.getPressure()!.toStringAsFixed(1)} hPa',
                            Colors.indigo),
                      ],
                      if (currentWeather.getAltitude() != null) ...[
                        const Divider(),
                        _buildDetailRow(
                            Icons.height,
                            'Altitude',
                            '${currentWeather.getAltitude()!.toStringAsFixed(1)} m',
                            Colors.purple),
                      ],
                      if (currentWeather.getSoilMoisture() != null) ...[
                        const Divider(),
                        _buildDetailRow(
                            Icons.grass,
                            'Humidité du Sol',
                            '${currentWeather.getSoilMoisture()!.toStringAsFixed(1)} %',
                            Colors.brown),
                      ],
                      if (currentWeather.getLightIntensity() != null) ...[
                        const Divider(),
                        _buildDetailRow(
                            Icons.wb_sunny,
                            'Luminosité',
                            '${currentWeather.getLightIntensity()!.toStringAsFixed(1)} lux',
                            Colors.amber),
                      ],
                      if (currentWeather.getRainfall() != null) ...[
                        const Divider(),
                        _buildDetailRow(
                            Icons.umbrella,
                            'Précipitations',
                            '${currentWeather.getRainfall()!.toStringAsFixed(1)} mm',
                            Colors.lightBlue),
                      ],
                      const Divider(),
                      _buildComfortIndicator(currentWeather),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                )),
                child: AnimatedWeatherCard(
                  title: 'Conseils du jour',
                  icon: Icons.tips_and_updates,
                  color: Colors.amber,
                  child: _buildWeatherTips(currentWeather),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLastUpdateText(DateTime? lastUpdateTime) {
    if (lastUpdateTime == null) return "Pas encore mis à jour";

    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);

    if (difference.inSeconds < 60) {
      return "Mis à jour il y a ${difference.inSeconds} secondes";
    } else if (difference.inMinutes < 60) {
      return "Mis à jour il y a ${difference.inMinutes} minutes";
    } else if (difference.inHours < 24) {
      return "Mis à jour il y a ${difference.inHours} heures";
    } else {
      return "Mis à jour il y a ${difference.inDays} jours";
    }
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComfortIndicator(dynamic currentWeather) {
    double comfortIndex = 0;
    String comfortText = '';
    Color comfortColor = Colors.green;

    if (currentWeather.temperature > 15 &&
        currentWeather.temperature < 25 &&
        currentWeather.humidity > 30 &&
        currentWeather.humidity < 70) {
      comfortIndex = 0.9;
      comfortText = 'Très confortable';
      comfortColor = Colors.green;
    } else if (currentWeather.temperature > 10 &&
        currentWeather.temperature < 30 &&
        currentWeather.humidity > 20 &&
        currentWeather.humidity < 80) {
      comfortIndex = 0.7;
      comfortText = 'Confortable';
      comfortColor = Colors.lightGreen;
    } else if (currentWeather.temperature > 5 &&
        currentWeather.temperature < 35) {
      comfortIndex = 0.4;
      comfortText = 'Acceptable';
      comfortColor = Colors.orange;
    } else {
      comfortIndex = 0.2;
      comfortText = 'Inconfortable';
      comfortColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sentiment_satisfied_alt, color: comfortColor, size: 28),
            const SizedBox(width: 16),
            const Text('Indice de confort', style: TextStyle(fontSize: 16)),
            const Spacer(),
            Text(
              comfortText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: comfortColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: comfortIndex,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(comfortColor),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildWeatherTips(dynamic currentWeather) {
    String tip = '';
    IconData tipIcon = Icons.lightbulb;

    if (currentWeather.temperature > 30) {
      tip =
          'Il fait chaud aujourd\'hui ! Hydratez-vous bien et évitez le soleil aux heures chaudes.';
      tipIcon = Icons.wb_sunny;
    } else if (currentWeather.temperature < 10) {
      tip = 'Il fait frais. Pensez à bien vous couvrir.';
      tipIcon = Icons.ac_unit;
    } else if (currentWeather.humidity > 80) {
      tip = 'Humidité élevée, un parapluie pourrait être utile.';
      tipIcon = Icons.umbrella;
    } else if (currentWeather.windSpeed > 30) {
      tip = 'Vents forts, soyez vigilant dehors.';
      tipIcon = Icons.air;
    } else {
      tip = 'Temps agréable pour sortir et profiter !';
      tipIcon = Icons.emoji_nature;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(tipIcon, color: Colors.amber, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
