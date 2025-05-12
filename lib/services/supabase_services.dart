import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  static const String supabaseUrl = 'https://ysvztdjsfodgoqobflar.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlzdnp0ZGpzZm9kZ29xb2JmbGFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1MTg0MzIsImV4cCI6MjA2MTA5NDQzMn0.ZH_B0-nN4DcL244e19E-xuLNJQwgoVR7ZgXMknDxRDE';

  late final SupabaseClient client;

  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      client = Supabase.instance.client;
      debugPrint('Supabase initialisé');
    } catch (e) {
      debugPrint('Erreur d\'initialisation Supabase: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé',
        };
      }

      final userData =
          await client.from('users').select().eq('id', user.id).single();

      return {
        'success': true,
        'user': user,
        'userData': userData,
      };
    } catch (e) {
      debugPrint('Erreur login : $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        },
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'message': 'Échec de l\'inscription',
        };
      }

      await client.from('users').insert({
        'id': authResponse.user!.id,
        'username': username,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Inscription réussie',
        'user': authResponse.user,
      };
    } catch (e) {
      debugPrint('Erreur d\'inscription : $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
