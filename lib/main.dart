import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_meteo/providers/auth_providers.dart';
import 'package:station_meteo/providers/weather_providers.dart';
import 'package:station_meteo/screens/login_screen.dart';
import 'package:station_meteo/screens/home_screen.dart';
import 'package:station_meteo/services/mqtt_services.dart';
import 'package:station_meteo/services/sensor_simulator_services.dart';
import 'package:station_meteo/models/weather_data.dart';
import 'package:flutter/foundation.dart';
import 'package:station_meteo/services/supabase_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await SupabaseService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        Provider<MqttService>(
          create: (context) {
            final mqttService = MqttService();

            // Connecter le service MQTT au WeatherProvider
            mqttService.onWeatherDataReceived = (WeatherData data) {
              final weatherProvider =
                  Provider.of<WeatherProvider>(context, listen: false);
              weatherProvider.updateCurrentWeather(data);
              weatherProvider.addHistoricalData(data);
            };

            // Initialiser le service MQTT
            mqttService.initialize();

            return mqttService;
          },
          dispose: (_, mqttService) => mqttService.dispose(),
        ),
        Provider<SensorSimulatorService>(
          create: (context) {
            final simulatorService = SensorSimulatorService();

            // Connecter le service de simulation au WeatherProvider
            simulatorService.onSimulatedDataReceived = (WeatherData data) {
              final weatherProvider =
                  Provider.of<WeatherProvider>(context, listen: false);
              weatherProvider.updateCurrentWeather(data);
              weatherProvider.addHistoricalData(data);
            };

            // Démarrer la simulation si en mode debug
            if (kDebugMode) {
              simulatorService.startSimulation();
            }

            return simulatorService;
          },
          dispose: (_, simulatorService) => simulatorService.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Station Météo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Vérifier si l'utilisateur est connecté
            return authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
