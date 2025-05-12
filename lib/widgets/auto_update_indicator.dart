import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_meteo/providers/weather_providers.dart';
import 'package:station_meteo/services/mqtt_services.dart';

class AutoUpdateIndicator extends StatelessWidget {
  const AutoUpdateIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MqttService>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);

    // Vérifier si le service MQTT est connecté
    final isConnected = mqttService.isConnected;

    // Vérifier si des données ont été reçues
    final hasData = weatherProvider.currentWeather != null;

    // Vérifier quand les dernières données ont été reçues
    final lastUpdateTime = weatherProvider.lastUpdateTime;
    final now = DateTime.now();
    final timeSinceLastUpdate = lastUpdateTime != null
        ? now.difference(lastUpdateTime)
        : const Duration(hours: 1);

    // Déterminer l'état de la mise à jour automatique
    AutoUpdateStatus status;
    if (!isConnected) {
      status = AutoUpdateStatus.disconnected;
    } else if (!hasData) {
      status = AutoUpdateStatus.waiting;
    } else if (timeSinceLastUpdate.inMinutes < 1) {
      status = AutoUpdateStatus.active;
    } else if (timeSinceLastUpdate.inMinutes < 5) {
      status = AutoUpdateStatus.slow;
    } else {
      status = AutoUpdateStatus.inactive;
    }

    // Définir les propriétés visuelles en fonction de l'état
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (status) {
      case AutoUpdateStatus.active:
        statusIcon = Icons.sync;
        statusColor = Colors.green;
        statusText = 'Mise à jour auto active';
        break;
      case AutoUpdateStatus.slow:
        statusIcon = Icons.sync_problem;
        statusColor = Colors.orange;
        statusText = 'Mise à jour lente';
        break;
      case AutoUpdateStatus.waiting:
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.blue;
        statusText = 'En attente de données';
        break;
      case AutoUpdateStatus.inactive:
        statusIcon = Icons.sync_disabled;
        statusColor = Colors.red;
        statusText = 'Mise à jour inactive';
        break;
      case AutoUpdateStatus.disconnected:
      default:
        statusIcon = Icons.cloud_off;
        statusColor = Colors.grey;
        statusText = 'Déconnecté';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum AutoUpdateStatus {
  active,
  slow,
  waiting,
  inactive,
  disconnected,
}
