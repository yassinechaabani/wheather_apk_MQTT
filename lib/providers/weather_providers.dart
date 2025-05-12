import 'package:flutter/foundation.dart';
import 'package:station_meteo/models/weather_data.dart';

class WeatherProvider with ChangeNotifier {
  WeatherData? _currentWeather;
  final List<WeatherData> _historicalData = [];
  final Map<String, List<WeatherData>> _historicalDataByDay = {};

  // Ajout d'un timestamp pour la dernière mise à jour
  DateTime? _lastUpdateTime;

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherData> get historicalData => List.unmodifiable(_historicalData);
  Map<String, List<WeatherData>> get historicalDataByDay =>
      Map.unmodifiable(_historicalDataByDay);
  DateTime? get lastUpdateTime => _lastUpdateTime;

  void updateCurrentWeather(WeatherData data) {
    _currentWeather = data;
    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }

  void addHistoricalData(WeatherData data) {
    _historicalData.add(data);

    // Organiser par jour
    final day = _formatDay(data.timestamp);
    if (!_historicalDataByDay.containsKey(day)) {
      _historicalDataByDay[day] = [];
    }
    _historicalDataByDay[day]!.add(data);

    // Limiter l'historique à 1000 entrées
    if (_historicalData.length > 1000) {
      final removed = _historicalData.removeAt(0);
      final removedDay = _formatDay(removed.timestamp);
      _historicalDataByDay[removedDay]?.remove(removed);
      if (_historicalDataByDay[removedDay]?.isEmpty ?? false) {
        _historicalDataByDay.remove(removedDay);
      }
    }

    notifyListeners();
  }

  String _formatDay(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double getAverageTemperatureForDay(String day) {
    final dayData = _historicalDataByDay[day];
    if (dayData == null || dayData.isEmpty) {
      return 0;
    }
    final sum =
        dayData.fold<double>(0.0, (sum, data) => sum + data.temperature);
    return sum / dayData.length;
  }

  double getAverageHumidityForDay(String day) {
    final dayData = _historicalDataByDay[day];
    if (dayData == null || dayData.isEmpty) {
      return 0;
    }
    final sum = dayData.fold<double>(0.0, (sum, data) => sum + data.humidity);
    return sum / dayData.length;
  }

  double getAverageWindSpeedForDay(String day) {
    final dayData = _historicalDataByDay[day];
    if (dayData == null || dayData.isEmpty) {
      return 0;
    }
    final sum = dayData.fold<double>(0.0, (sum, data) => sum + data.windSpeed);
    return sum / dayData.length;
  }

  // Obtenir les données moyennes pour un capteur spécifique
  Map<String, dynamic>? getAverageSensorDataForDay(
      String day, String sensorType) {
    final dayData = _historicalDataByDay[day];
    if (dayData == null || dayData.isEmpty) {
      return null;
    }

    // Filtrer les données qui contiennent ce capteur
    final sensorData = dayData
        .where((data) => data.sensorData.containsKey(sensorType))
        .toList();

    if (sensorData.isEmpty) {
      return null;
    }

    // Calculer les moyennes pour chaque propriété du capteur
    final result = <String, dynamic>{};

    // Obtenir toutes les propriétés possibles pour ce type de capteur
    final allProperties = <String>{};
    for (var data in sensorData) {
      if (data.sensorData[sensorType] is Map) {
        allProperties
            .addAll((data.sensorData[sensorType] as Map).keys.cast<String>());
      }
    }

    // Calculer la moyenne pour chaque propriété
    for (var property in allProperties) {
      double sum = 0;
      int count = 0;

      for (var data in sensorData) {
        if (data.sensorData[sensorType] is Map &&
            (data.sensorData[sensorType] as Map).containsKey(property) &&
            (data.sensorData[sensorType][property] is num)) {
          sum += (data.sensorData[sensorType][property] as num).toDouble();
          count++;
        }
      }

      if (count > 0) {
        result[property] = sum / count;
      }
    }

    return result;
  }

  void clearData() {
    _currentWeather = null;
    _historicalData.clear();
    _historicalDataByDay.clear();
    _lastUpdateTime = null;
    notifyListeners();
  }
}
