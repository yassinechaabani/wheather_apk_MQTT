import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_meteo/services/sensor_simulator_services.dart';
import 'package:station_meteo/widgets/animated_weather_card.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({Key? key}) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final List<SensorSimulationConfig> _sensors = [
    SensorSimulationConfig(
      id: 'dht22',
      name: 'DHT22',
      description: 'Température et humidité',
      isEnabled: true,
    ),
    SensorSimulationConfig(
      id: 'bmp280',
      name: 'BMP280',
      description: 'Pression et altitude',
      isEnabled: true,
    ),
    SensorSimulationConfig(
      id: 'anemometer',
      name: 'Anémomètre',
      description: 'Vitesse et direction du vent',
      isEnabled: true,
    ),
    SensorSimulationConfig(
      id: 'soil_moisture',
      name: 'Humidité du sol',
      description: 'Niveau d\'humidité dans le sol',
      isEnabled: false,
    ),
    SensorSimulationConfig(
      id: 'light_sensor',
      name: 'Capteur de lumière',
      description: 'Intensité lumineuse',
      isEnabled: false,
    ),
    SensorSimulationConfig(
      id: 'rain_gauge',
      name: 'Pluviomètre',
      description: 'Quantité de précipitations',
      isEnabled: false,
    ),
  ];

  int _simulationInterval = 10;

  @override
  Widget build(BuildContext context) {
    final simulatorService =
        Provider.of<SensorSimulatorService>(context, listen: false);
    final isSimulating = simulatorService.isSimulating;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.science),
            SizedBox(width: 8),
            Text('Simulation des Capteurs'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedWeatherCard(
              title: 'Configuration de la Simulation',
              icon: Icons.settings,
              color: Colors.purple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cette fonctionnalité permet de simuler des données de capteurs pour tester l\'application sans matériel physique.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Intervalle de simulation
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        'Intervalle de simulation:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text('$_simulationInterval secondes'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _simulationInterval > 1
                            ? () {
                                setState(() {
                                  _simulationInterval--;
                                });
                                simulatorService.simulationInterval =
                                    _simulationInterval;
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _simulationInterval < 60
                            ? () {
                                setState(() {
                                  _simulationInterval++;
                                });
                                simulatorService.simulationInterval =
                                    _simulationInterval;
                              }
                            : null,
                      ),
                    ],
                  ),

                  const Divider(),

                  // Statut de la simulation
                  Row(
                    children: [
                      Icon(
                        isSimulating ? Icons.play_circle : Icons.pause_circle,
                        color: isSimulating ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Statut: ${isSimulating ? 'En cours' : 'Arrêtée'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSimulating ? Colors.green : Colors.red,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (isSimulating) {
                            simulatorService.stopSimulation();
                          } else {
                            // Mettre à jour les capteurs à simuler
                            final sensorsToSimulate = _sensors
                                .where((s) => s.isEnabled)
                                .map((s) => s.id)
                                .toList();

                            simulatorService
                                .configureSensorsToSimulate(sensorsToSimulate);
                            simulatorService.startSimulation();
                          }
                          setState(() {});
                        },
                        icon:
                            Icon(isSimulating ? Icons.stop : Icons.play_arrow),
                        label: Text(isSimulating ? 'Arrêter' : 'Démarrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSimulating ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedWeatherCard(
              title: 'Capteurs à Simuler',
              icon: Icons.sensors,
              color: Colors.teal,
              child: Column(
                children: [
                  const Text(
                    'Sélectionnez les capteurs que vous souhaitez simuler:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ..._sensors.map((sensor) => _buildSensorSwitch(sensor)),
                ],
              ),
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
      ),
    );
  }

  Widget _buildSensorSwitch(SensorSimulationConfig sensor) {
    return SwitchListTile(
      title: Text(
        sensor.name,
        style: TextStyle(
          fontWeight: sensor.isEnabled ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(sensor.description),
      value: sensor.isEnabled,
      onChanged: (value) {
        setState(() {
          sensor.isEnabled = value;
        });
      },
      activeColor: Colors.teal,
    );
  }
}

class SensorSimulationConfig {
  final String id;
  final String name;
  final String description;
  bool isEnabled;

  SensorSimulationConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
  });
}
