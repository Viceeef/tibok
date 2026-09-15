import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class BloodPressureService {
  BloodPressureService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in.');
    }

    return user.id;
  }

  Future<List<Map<String, dynamic>>> getRecentReadings() async {
    final response = await _client
        .from('blood_pressure_logs')
        .select()
        .eq('user_id', _currentUserId)
        .order('logged_at', ascending: false)
        .limit(30);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addReading({
    required int systolic,
    required int diastolic,
    required int heartRate,
    String? notes,
  }) async {
    if (systolic < 50 || systolic > 250) {
      throw Exception(
        'Systolic pressure must be between 50 and 250 mmHg.',
      );
    }

    if (diastolic < 30 || diastolic > 150) {
      throw Exception(
        'Diastolic pressure must be between 30 and 150 mmHg.',
      );
    }

    if (systolic <= diastolic) {
      throw Exception(
        'Systolic pressure must be higher than diastolic pressure.',
      );
    }

    if (heartRate < 30 || heartRate > 220) {
      throw Exception(
        'Heart rate must be between 30 and 220 bpm.',
      );
    }

    await _client.from('blood_pressure_logs').insert({
      'user_id': _currentUserId,
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'category': _getCategory(
        systolic,
        diastolic,
      ),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    });
  }

  Future<void> deleteReading(String id) async {
    await _client
        .from('blood_pressure_logs')
        .delete()
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }

  String _getCategory(
    int systolic,
    int diastolic,
  ) {
    if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    }

    if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
      return 'Elevated';
    }

    return 'High';
  }
}
