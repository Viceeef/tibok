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

  static const String passwordResetRedirectUrl = 'tibok://reset-password';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  static SupabaseClient get client {
    return Supabase.instance.client;
  }

  static User? get currentUser {
    return client.auth.currentUser;
  }

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

  static Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    final cleanedEmail = email.trim();

    if (cleanedEmail.isEmpty) {
      throw Exception(
        'Email address is required.',
      );
    }

    await client.auth.resetPasswordForEmail(
      cleanedEmail,
      redirectTo: passwordResetRedirectUrl,
    );
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final email = user.email;

    if (email == null || email.trim().isEmpty) {
      throw Exception(
        'Your account does not have an email address.',
      );
    }

    if (currentPassword.isEmpty) {
      throw Exception(
        'Current password is required.',
      );
    }

    if (newPassword.length < 8) {
      throw Exception(
        'New password must contain at least 8 characters.',
      );
    }

    if (currentPassword == newPassword) {
      throw Exception(
        'New password must be different from the current password.',
      );
    }

    //
    // Verify the current password before changing anything.
    //
    final verification = await client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    final verifiedUser = verification.user;

    if (verifiedUser == null) {
      throw Exception(
        'Current password is incorrect.',
      );
    }

    if (verifiedUser.id != user.id) {
      await client.auth.signOut();

      throw Exception(
        'Account verification failed.',
      );
    }

    await client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  static Future<void> updateRecoveredPassword({
    required String newPassword,
  }) async {
    if (currentUser == null) {
      throw Exception(
        'No password recovery session is active.',
      );
    }

    if (newPassword.length < 8) {
      throw Exception(
        'Password must contain at least 8 characters.',
      );
    }

    await client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  static Future<void> saveHealthProfile({
    required int age,
    required bool hasHypertension,
    required int baselineSystolic,
    required int baselineDiastolic,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'No user logged in.',
      );
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
        .eq(
          'user_id',
          user.id,
        )
        .maybeSingle();

    return response;
  }
}
