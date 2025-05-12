import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_meteo/widgets/animated_weather_card.dart';

class SensorSettingsScreen extends StatefulWidget {
  const SensorSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SensorSettingsScreen> createState() => _SensorSettingsScreenState();
}

class _SensorSettingsScreenState extends State<SensorSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;

  // Liste des capteurs disponibles
  final List<SensorConfig> _sensors = [
    SensorConfig(
      id: 'dht11',
      name: 'DHT11',
      description: 'Capteur de température et d\'humidité',
      icon: Icons.thermostat,
      color: Colors.red,
      isEnabled: false,
    ),
    SensorConfig(
      id: 'dht22',
      name: 'DHT22',
      description: 'Capteur de température et d\'humidité (haute précision)',
      icon: Icons.thermostat,
      color: Colors.orange,
      isEnabled: false,
    ),
    SensorConfig(
      id: 'bmp280',
      name: 'BMP280',
      description: 'Capteur de pression atmosphérique et d\'altitude',
      icon: Icons.compress,
      color: Colors.blue,
      isEnabled: false,
    ),
    SensorConfig(
      id: 'anemometer',
      name: 'Anémomètre',
      description: 'Capteur de vitesse du vent',
      icon: Icons.air,
      color: Colors.teal,
      isEnabled: false,
    ),
    SensorConfig(
      id: 'soil_moisture',
      name: 'Capteur d\'humidité du sol',
      description: 'Mesure l\'humidité dans le sol',
      icon: Icons.grass,
      color: Colors.brown,
      isEnabled: false,
    ),
    SensorConfig(
      id: 'light_sensor',
      name: 'Capteur de lumière',
      description: 'Mesure l\'intensité lumineuse',
      icon: Icons.wb_sunny,
      color: Colors.amber,
      isEnabled: false,
    ),
    SensorConfig(
      id: 'rain_gauge',
      name: 'Pluviomètre',
      description: 'Mesure les précipitations',
      icon: Icons.umbrella,
      color: Colors.lightBlue,
      isEnabled: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadSensorSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSensorSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      for (var sensor in _sensors) {
        final isEnabled = prefs.getBool('sensor_${sensor.id}_enabled') ?? false;
        sensor.isEnabled = isEnabled;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres des capteurs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _saveSensorSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      for (var sensor in _sensors) {
        await prefs.setBool('sensor_${sensor.id}_enabled', sensor.isEnabled);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres des capteurs sauvegardés'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint(
          'Erreur lors de la sauvegarde des paramètres des capteurs: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sensors),
            SizedBox(width: 8),
            Text('Configuration des Capteurs'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    )),
                    child: AnimatedWeatherCard(
                      title: 'Capteurs Disponibles',
                      icon: Icons.devices,
                      color: Colors.purple,
                      child: Column(
                        children: [
                          const Text(
                            'Activez les capteurs que vous utilisez dans votre station météo. Les données de ces capteurs seront affichées dans l\'application.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ..._sensors
                              .map((sensor) => _buildSensorSwitch(sensor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                    )),
                    child: AnimatedWeatherCard(
                      title: 'Format des Données JSON',
                      icon: Icons.code,
                      color: Colors.indigo,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Voici le format attendu des données JSON pour chaque capteur:',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          _buildJsonExample(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saveSensorSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Sauvegarder les paramètres'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSensorSwitch(SensorConfig sensor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sensor.isEnabled ? sensor.color : Colors.grey.shade300,
          width: sensor.isEnabled ? 2 : 1,
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(sensor.icon, color: sensor.color),
            const SizedBox(width: 8),
            Text(
              sensor.name,
              style: TextStyle(
                fontWeight:
                    sensor.isEnabled ? FontWeight.bold : FontWeight.normal,
                color: sensor.isEnabled ? sensor.color : Colors.black,
              ),
            ),
          ],
        ),
        subtitle: Text(
          sensor.description,
          style: TextStyle(
            fontSize: 12,
            color: sensor.isEnabled ? Colors.black87 : Colors.grey,
          ),
        ),
        value: sensor.isEnabled,
        onChanged: (value) {
          setState(() {
            sensor.isEnabled = value;
          });
        },
        activeColor: sensor.color,
      ),
    );
  }

  Widget _buildJsonExample() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          '''
{
  "dht11": {
    "temperature": 25.4,
    "humidity": 65.2
  },
  "bmp280": {
    "temperature": 25.1,
    "pressure": 1013.25,
    "altitude": 120.5
  },
  "anemometer": {
    "speed": 15.2,
    "direction": 180
  },
  "soil_moisture": {
    "value": 45.8
  },
  "light_sensor": {
    "value": 1250.5
  },
  "rain_gauge": {
    "value": 2.5
  }
}
''',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

class SensorConfig {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  bool isEnabled;

  SensorConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isEnabled,
  });
}
