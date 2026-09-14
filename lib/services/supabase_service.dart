import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ypessmdoyiahabobcaux.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_KxAHPE6tZeK43PWUAz2UyQ_PI1BUlC0',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
      },
    );

    final user = response.user;

    if (user != null) {
      await client.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'email': email,
      });
    }

    return response;
  }

  static Future<void> saveHealthProfile({
    required int age,
    required bool hasHypertension,
    required int baselineSystolic,
    required int baselineDiastolic,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No user logged in.');
    }

    final int dailyLimit = hasHypertension ? 1500 : 2000;

    await client.from('health_profiles').upsert(
      {
        'user_id': user.id,
        'age': age,
        'has_hypertension': hasHypertension,
        'baseline_systolic': baselineSystolic,
        'baseline_diastolic': baselineDiastolic,
        'daily_sodium_limit': dailyLimit,
      },
      onConflict: 'user_id',
    );
  }

  static Future<Map<String, dynamic>?> getHealthProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final response = await client
        .from('health_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }
}
