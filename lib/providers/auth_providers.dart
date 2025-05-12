import 'package:flutter/foundation.dart';
import 'package:station_meteo/models/users.dart';
import 'package:station_meteo/services/supabase_services.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabaseService = SupabaseService();

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result =
        await _supabaseService.login(email: email, password: password);

    _isLoading = false;

    if (result['success']) {
      final userData = result['userData'];
      _currentUser = User(
        username: userData['username'],
        email: userData['email'],
        password: '', // Pas de mot de passe stocké localement
      );
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _supabaseService.registerUser(
        email: email,
        password: password,
        username: username,
      );

      _isLoading = false;

      if (result['success']) {
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }
}
