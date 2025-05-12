class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final DateTime timestamp;
  final Map<String, dynamic> sensorData; // Données brutes des capteurs

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.timestamp,
    this.sensorData = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'timestamp': timestamp.toIso8601String(),
      'sensorData': sensorData,
    };
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      sensorData: json['sensorData'] ?? {},
    );
  }

  // Création à partir des données brutes des capteurs
  factory WeatherData.fromSensorData(Map<String, dynamic> data) {
    // Valeurs par défaut
    double temperature = 0;
    double humidity = 0;
    double windSpeed = 0;

    // Extraire les données selon le type de capteur
    if (data.containsKey('dht11') || data.containsKey('dht22')) {
      final dhtData = data['dht11'] ?? data['dht22'] ?? {};
      temperature = (dhtData['temperature'] as num?)?.toDouble() ?? 0;
      humidity = (dhtData['humidity'] as num?)?.toDouble() ?? 0;
    }

    if (data.containsKey('bmp280')) {
      final bmpData = data['bmp280'] ?? {};
      // Si la température n'a pas été définie par un DHT, utiliser celle du BMP280
      if (temperature == 0) {
        temperature = (bmpData['temperature'] as num?)?.toDouble() ?? 0;
      }
      // Pression atmosphérique disponible dans les données du capteur
    }

    if (data.containsKey('anemometer')) {
      final anemometerData = data['anemometer'] ?? {};
      windSpeed = (anemometerData['speed'] as num?)?.toDouble() ?? 0;
    }

    return WeatherData(
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      timestamp: DateTime.now(),
      sensorData: data,
    );
  }

  // Méthodes pour accéder aux données spécifiques des capteurs
  double? getPressure() {
    if (sensorData.containsKey('bmp280')) {
      return (sensorData['bmp280']['pressure'] as num?)?.toDouble();
    }
    return null;
  }

  double? getAltitude() {
    if (sensorData.containsKey('bmp280')) {
      return (sensorData['bmp280']['altitude'] as num?)?.toDouble();
    }
    return null;
  }

  double? getSoilMoisture() {
    if (sensorData.containsKey('soil_moisture')) {
      return (sensorData['soil_moisture']['value'] as num?)?.toDouble();
    }
    return null;
  }

  double? getLightIntensity() {
    if (sensorData.containsKey('light_sensor')) {
      return (sensorData['light_sensor']['value'] as num?)?.toDouble();
    }
    return null;
  }

  double? getRainfall() {
    if (sensorData.containsKey('rain_gauge')) {
      return (sensorData['rain_gauge']['value'] as num?)?.toDouble();
    }
    return null;
  }

  // Obtenir la liste des capteurs disponibles
  List<String> getAvailableSensors() {
    return sensorData.keys.toList();
  }
}
