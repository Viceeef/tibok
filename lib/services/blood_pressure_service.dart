import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class BloodPressureService {
  BloodPressureService({
    SupabaseClient? client,
  }) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in.');
    }

    return user.id;
  }

  String classifyReading({
    required int systolic,
    required int diastolic,
  }) {
    // 2025 AHA/ACC adult BP categories.
    // A single reading is not a diagnosis.

    if (systolic > 180 || diastolic > 120) {
      return 'Severe Hypertension';
    }

    if (systolic >= 140 || diastolic >= 90) {
      return 'Stage 2 Hypertension';
    }

    if (systolic >= 130 || diastolic >= 80) {
      return 'Stage 1 Hypertension';
    }

    if (systolic >= 120 && diastolic < 80) {
      return 'Elevated';
    }

    return 'Normal';
  }

  Future<List<Map<String, dynamic>>> getRecentReadings({
    int limit = 100,
  }) async {
    final response = await _client
        .from('blood_pressure_logs')
        .select()
        .eq('user_id', _currentUserId)
        .order('logged_at', ascending: false)
        .limit(limit);

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

    if (heartRate < 30 || heartRate > 220) {
      throw Exception(
        'Heart rate must be between 30 and 220 bpm.',
      );
    }

    if (systolic <= diastolic) {
      throw Exception(
        'Systolic pressure must be higher than diastolic pressure.',
      );
    }

    final category = classifyReading(
      systolic: systolic,
      diastolic: diastolic,
    );

    await _client.from('blood_pressure_logs').insert({
      'user_id': _currentUserId,
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'category': category,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    });
  }

  Future<void> deleteReading(
    String readingId,
  ) async {
    await _client
        .from('blood_pressure_logs')
        .delete()
        .eq('id', readingId)
        .eq('user_id', _currentUserId);
  }
}
