import 'package:flutter/material.dart';
import 'package:station_meteo/services/mqtt_services.dart';
import 'package:station_meteo/widgets/animated_weather_card.dart';

class MqttSettingsScreen extends StatefulWidget {
  final MqttService mqttService;

  const MqttSettingsScreen({
    Key? key,
    required this.mqttService,
  }) : super(key: key);

  @override
  State<MqttSettingsScreen> createState() => _MqttSettingsScreenState();
}

class _MqttSettingsScreenState extends State<MqttSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _topicController;
  bool _useSSL = false;
  bool _isLoading = false;
  bool _isTesting = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _topicController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await widget.mqttService.getConnectionSettings();

      _hostController = TextEditingController(text: settings['host']);
      _portController =
          TextEditingController(text: settings['port'].toString());
      _usernameController = TextEditingController(text: settings['username']);
      _passwordController = TextEditingController(text: settings['password']);
      _topicController = TextEditingController(text: settings['topic']);
      _useSSL = settings['useSSL'];
    } catch (e) {
      _showSnackBar('Erreur lors du chargement des paramètres: $e');

      // Valeurs par défaut
      _hostController = TextEditingController(text: 'broker.hivemq.com');
      _portController = TextEditingController(text: '1883');
      _usernameController = TextEditingController(text: '');
      _passwordController = TextEditingController(text: '');
      _topicController = TextEditingController(text: 'weather/data');
      _useSSL = false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await widget.mqttService.saveSettings(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        topic: _topicController.text.trim(),
        useSSL: _useSSL,
      );

      setState(() {
        _statusMessage = 'Paramètres sauvegardés avec succès';
        _isSuccess = true;
      });

      _showSnackBar('Paramètres sauvegardés avec succès');
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur: $e';
        _isSuccess = false;
      });

      _showSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
      _statusMessage = '';
    });

    try {
      final success = await widget.mqttService.testConnection(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        useSSL: _useSSL,
      );

      setState(() {
        if (success) {
          _statusMessage = 'Connexion réussie';
          _isSuccess = true;
        } else {
          _statusMessage = 'Échec de la connexion';
          _isSuccess = false;
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Configuration MQTT'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
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
                        title: 'Paramètres du Broker',
                        icon: Icons.cloud_queue,
                        color: Colors.blue,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _hostController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse du broker',
                                hintText: 'Ex: broker.hivemq.com',
                                prefixIcon: Icon(Icons.dns),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer l\'adresse du broker';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                hintText: 'Ex: 1883',
                                prefixIcon: Icon(Icons.settings_ethernet),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le port';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Veuillez entrer un nombre valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Utiliser SSL/TLS'),
                              subtitle: const Text(
                                  'Activer pour une connexion sécurisée'),
                              value: _useSSL,
                              onChanged: (value) {
                                setState(() {
                                  _useSSL = value;
                                  if (value && _portController.text == '1883') {
                                    _portController.text = '8883';
                                  } else if (!value &&
                                      _portController.text == '8883') {
                                    _portController.text = '1883';
                                  }
                                });
                              },
                              secondary: Icon(
                                _useSSL ? Icons.lock : Icons.lock_open,
                                color: _useSSL ? Colors.green : Colors.orange,
                              ),
                            ),
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
                        title: 'Authentification',
                        icon: Icons.security,
                        color: Colors.purple,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Nom d\'utilisateur (optionnel)',
                                hintText:
                                    'Laisser vide si pas d\'authentification',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe (optionnel)',
                                hintText:
                                    'Laisser vide si pas d\'authentification',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () {
                                    // Toggle password visibility
                                  },
                                ),
                              ),
                              obscureText: true,
                            ),
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
                        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                      )),
                      child: AnimatedWeatherCard(
                        title: 'Topic',
                        icon: Icons.topic,
                        color: Colors.teal,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _topicController,
                              decoration: const InputDecoration(
                                labelText: 'Topic MQTT',
                                hintText: 'Ex: weather/data',
                                prefixIcon: Icon(Icons.label),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le topic';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Format attendu des données JSON:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                '{\n  "temperature": 25.5,\n  "humidity": 60.0,\n  "windSpeed": 10.2\n}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle : Icons.error,
                              color: _isSuccess ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _isSuccess
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.wifi_tethering),
                            label: const Text('Tester la connexion'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveSettings,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Sauvegarder'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Informations sur Mosquitto
                    AnimatedWeatherCard(
                      title: 'À propos de Mosquitto',
                      icon: Icons.info_outline,
                      color: Colors.grey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mosquitto est un broker MQTT open source populaire. Pour l\'utiliser:',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            '1. Installation locale:',
                            'Téléchargez et installez Mosquitto depuis mosquitto.org',
                          ),
                          _buildInfoItem(
                            '2. Configuration:',
                            'Configurez le fichier mosquitto.conf pour définir les paramètres',
                          ),
                          _buildInfoItem(
                            '3. Démarrage:',
                            'Lancez le service Mosquitto sur votre machine',
                          ),
                          _buildInfoItem(
                            '4. Connexion:',
                            'Utilisez l\'adresse IP de votre machine comme hôte',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vous pouvez aussi utiliser un broker public comme:',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          _buildBrokerExample('broker.hivemq.com', '1883'),
                          _buildBrokerExample('broker.emqx.io', '1883'),
                          _buildBrokerExample(
                              'mqtt.eclipseprojects.io', '1883'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerExample(String host, String port) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hostController.text = host;
          _portController.text = port;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              '$host:$port',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.blue,
              ),
            ),
            const Spacer(),
            const Icon(Icons.touch_app, size: 14, color: Colors.blue),
            const Text(
              'Utiliser',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
