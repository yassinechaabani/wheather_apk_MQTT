import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AnimationUtils {
  // Vérifier la connectivité internet
  static Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // Obtenir l'URL d'animation en fonction de la condition météo
  static String getWeatherAnimationUrl(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'hot':
        return 'https://assets1.lottiefiles.com/private_files/lf30_rg5wrsf4.json';
      case 'rainy':
      case 'rain':
        return 'https://assets1.lottiefiles.com/private_files/lf30_rb778uhz.json';
      case 'cloudy':
      case 'cloud':
        return 'https://assets1.lottiefiles.com/private_files/lf30_jmgekfqr.json';
      case 'snowy':
      case 'snow':
        return 'https://assets1.lottiefiles.com/private_files/lf30_h8q2jyqy.json';
      case 'windy':
      case 'wind':
        return 'https://assets1.lottiefiles.com/private_files/lf30_aq0xpbxj.json';
      case 'loading':
        return 'https://assets1.lottiefiles.com/private_files/lf30_fup2uejx.json';
      case 'history':
        return 'https://assets1.lottiefiles.com/private_files/lf30_fuuisifo.json';
      default:
        return 'https://assets1.lottiefiles.com/private_files/lf30_jmgekfqr.json';
    }
  }

  // Obtenir l'icône de secours en cas d'échec de chargement
  static IconData getFallbackIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'hot':
        return Icons.wb_sunny;
      case 'rainy':
      case 'rain':
        return Icons.water_drop;
      case 'cloudy':
      case 'cloud':
        return Icons.cloud;
      case 'snowy':
      case 'snow':
        return Icons.ac_unit;
      case 'windy':
      case 'wind':
        return Icons.air;
      case 'loading':
        return Icons.hourglass_empty;
      case 'history':
        return Icons.history;
      default:
        return Icons.cloud;
    }
  }

  // Obtenir la couleur de l'icône de secours
  static Color getFallbackColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'hot':
        return Colors.orange;
      case 'rainy':
      case 'rain':
        return Colors.blue;
      case 'cloudy':
      case 'cloud':
        return Colors.grey;
      case 'snowy':
      case 'snow':
        return Colors.lightBlue;
      case 'windy':
      case 'wind':
        return Colors.teal;
      case 'loading':
        return Colors.purple;
      case 'history':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Déterminer la condition météo en fonction des données
  static String getWeatherCondition(
      double temperature, double humidity, double windSpeed) {
    if (temperature > 30) {
      return 'hot';
    } else if (humidity > 80) {
      return 'rain';
    } else if (windSpeed > 30) {
      return 'wind';
    } else if (temperature < 5) {
      return 'snow';
    } else if (humidity > 60) {
      return 'cloud';
    } else {
      return 'sunny';
    }
  }
}
