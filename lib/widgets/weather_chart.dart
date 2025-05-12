import 'package:flutter/material.dart';
import 'package:station_meteo/models/weather_data.dart';
import 'package:fl_chart/fl_chart.dart';

class WeatherChart extends StatelessWidget {
  final String title;
  final List<WeatherData> data;
  final double Function(WeatherData) valueSelector;
  final Color color;

  const WeatherChart({
    Key? key,
    required this.title,
    required this.data,
    required this.valueSelector,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort data by timestamp
    final sortedData = List<WeatherData>.from(data)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Create line chart data
    final spots = sortedData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = valueSelector(entry.value);
      return FlSpot(index, value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 &&
                          index < sortedData.length &&
                          index % (sortedData.length ~/ 5 + 1) == 0) {
                        final time = sortedData[index].timestamp;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: 0,
              maxX: (sortedData.length - 1).toDouble(),
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: false,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
