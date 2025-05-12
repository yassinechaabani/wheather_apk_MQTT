import 'package:flutter/material.dart';
import 'package:station_meteo/models/weather_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class InteractiveWeatherChart extends StatefulWidget {
  final String title;
  final List<WeatherData> data;
  final double Function(WeatherData) valueSelector;
  final Color color;

  const InteractiveWeatherChart({
    Key? key,
    required this.title,
    required this.data,
    required this.valueSelector,
    required this.color,
  }) : super(key: key);

  @override
  State<InteractiveWeatherChart> createState() =>
      _InteractiveWeatherChartState();
}

class _InteractiveWeatherChartState extends State<InteractiveWeatherChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
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
    // Sort data by timestamp
    final sortedData = List<WeatherData>.from(widget.data)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Create line chart data
    final spots = sortedData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = widget.valueSelector(entry.value);
      return FlSpot(index, value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIconForTitle(widget.title),
              color: widget.color,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
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
                                DateFormat('HH:mm').format(time),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
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
                              color: Colors.grey,
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
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  minX: 0,
                  maxX: (sortedData.length - 1).toDouble(),
                  minY: 0,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < sortedData.length) {
                            final data = sortedData[index];
                            final value = widget.valueSelector(data);
                            return LineTooltipItem(
                              '${DateFormat('HH:mm').format(data.timestamp)}\n${value.toStringAsFixed(1)} ${_getUnitForTitle(widget.title)}',
                              const TextStyle(color: Colors.white),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      setState(() {
                        if (event is FlPanEndEvent ||
                            event is FlTapUpEvent ||
                            touchResponse == null ||
                            touchResponse.lineBarSpots == null) {
                          _touchedIndex = null;
                        } else {
                          _touchedIndex =
                              touchResponse.lineBarSpots![0].x.toInt();
                        }
                      });
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots
                          .map((spot) =>
                              FlSpot(spot.x, spot.y * _animation.value))
                          .toList(),
                      isCurved: true,
                      color: widget.color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: index == _touchedIndex ? 6 : 3,
                            color: widget.color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: widget.color.withOpacity(0.2 * _animation.value),
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.4 * _animation.value),
                            widget.color.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Température')) {
      return Icons.thermostat;
    } else if (title.contains('Humidité')) {
      return Icons.water_drop;
    } else if (title.contains('Vent')) {
      return Icons.air;
    }
    return Icons.analytics;
  }

  String _getUnitForTitle(String title) {
    if (title.contains('Température')) {
      return '°C';
    } else if (title.contains('Humidité')) {
      return '%';
    } else if (title.contains('Vent')) {
      return 'km/h';
    }
    return '';
  }
}
