import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_meteo/providers/weather_providers.dart';
import 'package:station_meteo/widgets/interactive_weather_chart.dart';
import 'package:station_meteo/widgets/animated_weather_card.dart';
import 'package:station_meteo/widgets/safe_lottie_animation.dart';
import 'package:intl/intl.dart';

class HistoricalWeatherScreen extends StatefulWidget {
  const HistoricalWeatherScreen({Key? key}) : super(key: key);

  @override
  State<HistoricalWeatherScreen> createState() =>
      _HistoricalWeatherScreenState();
}

class _HistoricalWeatherScreenState extends State<HistoricalWeatherScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
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
        final historicalDataByDay = weatherProvider.historicalDataByDay;

        if (historicalDataByDay.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(height: 16),
                Text(
                  'Aucune donnée historique disponible',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Les données s\'afficheront ici au fur et à mesure',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final days = historicalDataByDay.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return DefaultTabController(
          length: days.length,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: days.map((day) {
                    return Tab(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(_formatDay(day)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: days.map((day) {
                    final dayData = historicalDataByDay[day]!;
                    final avgTemp =
                        weatherProvider.getAverageTemperatureForDay(day);
                    final avgHumidity =
                        weatherProvider.getAverageHumidityForDay(day);
                    final avgWindSpeed =
                        weatherProvider.getAverageWindSpeedForDay(day);

                    final temperatures =
                        dayData.map((d) => d.temperature).toList();
                    final humidities = dayData.map((d) => d.humidity).toList();
                    final windSpeeds = dayData.map((d) => d.windSpeed).toList();
                    final timestamps = dayData.map((d) => d.timestamp).toList();

                    final maxTemp = _getMaxValue(temperatures);
                    final minTemp = _getMinValue(temperatures);
                    final maxHumidity = _getMaxValue(humidities);
                    final maxWind = _getMaxValue(windSpeeds);
                    final firstMeasure = _getEarliestTimestamp(timestamps);
                    final lastMeasure = _getLatestTimestamp(timestamps);

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedWeatherCard(
                              title: 'Résumé du ${_formatDay(day)}',
                              icon: Icons.summarize,
                              color: Colors.teal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                      Icons.thermostat,
                                      'Température moyenne',
                                      '${avgTemp.toStringAsFixed(1)} °C',
                                      Colors.red),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                      Icons.water_drop,
                                      'Humidité moyenne',
                                      '${avgHumidity.toStringAsFixed(1)} %',
                                      Colors.blue),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                      Icons.air,
                                      'Vitesse du vent moyenne',
                                      '${avgWindSpeed.toStringAsFixed(1)} km/h',
                                      Colors.green),
                                  const SizedBox(height: 16),
                                  _buildWeatherSummary(
                                      avgTemp, avgHumidity, avgWindSpeed),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedWeatherCard(
                              title: 'Graphiques',
                              icon: Icons.show_chart,
                              color: Colors.purple,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Appuyez sur les graphiques pour voir les détails',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: InteractiveWeatherChart(
                                      title: 'Température (°C)',
                                      data: dayData,
                                      valueSelector: (d) => d.temperature,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 200,
                                    child: InteractiveWeatherChart(
                                      title: 'Humidité (%)',
                                      data: dayData,
                                      valueSelector: (d) => d.humidity,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 200,
                                    child: InteractiveWeatherChart(
                                      title: 'Vitesse du Vent (km/h)',
                                      data: dayData,
                                      valueSelector: (d) => d.windSpeed,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedWeatherCard(
                              title: 'Statistiques',
                              icon: Icons.analytics,
                              color: Colors.amber,
                              child: Column(
                                children: [
                                  _buildStatisticRow('Nombre de mesures',
                                      '${dayData.length}', Icons.numbers),
                                  const Divider(),
                                  _buildStatisticRow(
                                      'Température max',
                                      '${maxTemp.toStringAsFixed(1)} °C',
                                      Icons.thermostat),
                                  const Divider(),
                                  _buildStatisticRow(
                                      'Température min',
                                      '${minTemp.toStringAsFixed(1)} °C',
                                      Icons.thermostat),
                                  const Divider(),
                                  _buildStatisticRow(
                                      'Humidité max',
                                      '${maxHumidity.toStringAsFixed(1)} %',
                                      Icons.water_drop),
                                  const Divider(),
                                  _buildStatisticRow(
                                      'Vent max',
                                      '${maxWind.toStringAsFixed(1)} km/h',
                                      Icons.air),
                                  const Divider(),
                                  _buildStatisticRow(
                                      'Première mesure',
                                      DateFormat('HH:mm').format(firstMeasure),
                                      Icons.timer),
                                  const Divider(),
                                  _buildStatisticRow(
                                      'Dernière mesure',
                                      DateFormat('HH:mm').format(lastMeasure),
                                      Icons.timer_off),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helpers pour valeurs min/max/timestamp

  double _getMaxValue(List<double> values) =>
      values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;

  double _getMinValue(List<double> values) =>
      values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0.0;

  DateTime _getEarliestTimestamp(List<DateTime> values) => values.isNotEmpty
      ? values.reduce((a, b) => a.isBefore(b) ? a : b)
      : DateTime.now();

  DateTime _getLatestTimestamp(List<DateTime> values) => values.isNotEmpty
      ? values.reduce((a, b) => a.isAfter(b) ? a : b)
      : DateTime.now();

  String _formatDay(String day) {
    final date = DateTime.tryParse(day);
    if (date == null) return day;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildSummaryRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWeatherSummary(
      double avgTemp, double avgHumidity, double avgWindSpeed) {
    String summary;
    IconData summaryIcon;
    Color summaryColor;

    if (avgTemp > 25) {
      summary = 'Journée chaude';
      summaryIcon = Icons.wb_sunny;
      summaryColor = Colors.orange;
    } else if (avgTemp < 10) {
      summary = 'Journée fraîche';
      summaryIcon = Icons.ac_unit;
      summaryColor = Colors.lightBlue;
    } else if (avgHumidity > 80) {
      summary = 'Journée humide';
      summaryIcon = Icons.water;
      summaryColor = Colors.blue;
    } else if (avgWindSpeed > 30) {
      summary = 'Journée venteuse';
      summaryIcon = Icons.air;
      summaryColor = Colors.teal;
    } else {
      summary = 'Journée agréable';
      summaryIcon = Icons.wb_twilight;
      summaryColor = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: summaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: summaryColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(summaryIcon, color: summaryColor, size: 32),
          const SizedBox(width: 16),
          Text(
            summary,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: summaryColor),
          ),
        ],
      ),
    );
  }
}
