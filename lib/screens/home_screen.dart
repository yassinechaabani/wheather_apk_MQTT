import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_meteo/providers/auth_providers.dart';
import 'package:station_meteo/screens/current_wheather_screen.dart';
import 'package:station_meteo/screens/historical_weather_screen.dart';
import 'package:station_meteo/screens/mqtt_settings_screen.dart';
import 'package:station_meteo/screens/sensor_settings_screen.dart';
import 'package:station_meteo/screens/sensor_debug_screen.dart';
import 'package:station_meteo/screens/simulation_screen.dart';
import 'package:station_meteo/services/mqtt_services.dart';
import 'package:station_meteo/widgets/safe_lottie_animation.dart';
import 'package:station_meteo/widgets/auto_update_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const CurrentWeatherScreen(),
    const HistoricalWeatherScreen(),
  ];

  final List<String> _titles = [
    'Météo Actuelle',
    'Historique Météo',
  ];

  final List<IconData> _icons = [
    Icons.cloud,
    Icons.history,
  ];

  final List<String> _animationTypes = [
    'sunny',
    'history',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final mqttService = Provider.of<MqttService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_icons[_selectedIndex]),
            const SizedBox(width: 8),
            Text(_titles[_selectedIndex]),
          ],
        ),
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Indicateur de statut MQTT
          StreamBuilder<ConnectionStatus>(
            stream: mqttService.connectionStatus,
            initialData: mqttService.isConnected
                ? ConnectionStatus.connected
                : ConnectionStatus.disconnected,
            builder: (context, snapshot) {
              final status = snapshot.data ?? ConnectionStatus.disconnected;
              IconData statusIcon;
              Color statusColor;
              String statusText;

              switch (status) {
                case ConnectionStatus.connected:
                  statusIcon = Icons.cloud_done;
                  statusColor = Colors.green;
                  statusText = 'Connecté';
                  break;
                case ConnectionStatus.connecting:
                  statusIcon = Icons.cloud_sync;
                  statusColor = Colors.orange;
                  statusText = 'Connexion...';
                  break;
                case ConnectionStatus.failed:
                  statusIcon = Icons.cloud_off;
                  statusColor = Colors.red;
                  statusText = 'Échec';
                  break;
                case ConnectionStatus.disconnected:
                default:
                  statusIcon = Icons.cloud_off;
                  statusColor = Colors.grey;
                  statusText = 'Déconnecté';
                  break;
              }

              return Tooltip(
                message: statusText,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          const AutoUpdateIndicator(),

          // Menu de configuration
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
            onSelected: (value) {
              switch (value) {
                case 'mqtt':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MqttSettingsScreen(
                        mqttService: mqttService,
                      ),
                    ),
                  );
                  break;
                case 'sensors':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SensorSettingsScreen(),
                    ),
                  );
                  break;
                case 'sensor_debug':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SensorDebugScreen(),
                    ),
                  );
                  break;
                case 'simulation': // ✅ case simulation ajouté
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimulationScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'mqtt',
                child: Row(
                  children: [
                    Icon(Icons.cloud_queue, size: 20),
                    SizedBox(width: 8),
                    Text('Paramètres MQTT'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'sensors',
                child: Row(
                  children: [
                    Icon(Icons.sensors, size: 20),
                    SizedBox(width: 8),
                    Text('Paramètres des Capteurs'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'sensor_debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 20),
                    SizedBox(width: 8),
                    Text('Débogage des Capteurs'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'simulation',
                child: Row(
                  children: [
                    Icon(Icons.science, size: 20),
                    SizedBox(width: 8),
                    Text('Simulation des Capteurs'),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentUser?.username ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content:
                      const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        authProvider.logout();
                      },
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: _selectedIndex == 0
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: SafeLottieAnimation(
                        animationType: _animationTypes[0],
                        width: 32,
                        height: 32,
                      ),
                    )
                  : const Icon(Icons.cloud),
              label: 'Actuel',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 1
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: SafeLottieAnimation(
                        animationType: _animationTypes[1],
                        width: 32,
                        height: 32,
                      ),
                    )
                  : const Icon(Icons.history),
              label: 'Historique',
            ),
          ],
        ),
      ),
      floatingActionButton: mqttService.isConnected
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await mqttService.connect();
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.refresh),
              tooltip: 'Reconnecter au broker MQTT',
            ),
    );
  }
}
