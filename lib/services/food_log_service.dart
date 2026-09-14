import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_service.dart';

class FoodLogService {
  FoodLogService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const Uuid _uuid = Uuid();

  /// Tibok is a Philippine-focused MVP.
  /// Always use Philippine Standard Time (UTC+8) for daily logs.
  DateTime get philippineNow {
    return DateTime.now().toUtc().add(
          const Duration(hours: 8),
        );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String createRequestId() => _uuid.v4();

  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in.');
    }

    return user.id;
  }

  Future<String> addFoodLog({
    required String requestId,
    required String foodName,
    required int sodiumAmount,
    DateTime? logDate,
    required String entryType,
    String? sourceBarcode,
    double servings = 1,
    int? sodiumPerServingMg,
  }) async {
    if (foodName.trim().isEmpty) {
      throw Exception('Food name is required.');
    }

    if (sodiumAmount < 0) {
      throw Exception('Sodium cannot be negative.');
    }

    if (servings <= 0) {
      throw Exception('Servings must be greater than zero.');
    }

    if (!['manual', 'scanned', 'searched'].contains(entryType)) {
      throw Exception('Invalid food entry type.');
    }

    final effectiveDate = logDate ?? philippineNow;

    final response = await _client.rpc(
      'tibok_add_food_log',
      params: {
        'p_request_id': requestId,
        'p_food_name': foodName.trim(),
        'p_sodium_amount': sodiumAmount,
        'p_log_date': _formatDate(effectiveDate),
        'p_entry_type': entryType,
        'p_source_barcode': sourceBarcode,
        'p_servings': servings,
        'p_sodium_per_serving': sodiumPerServingMg,
      },
    );

    if (response == null) {
      throw Exception(
        'The saved food entry could not be confirmed.',
      );
    }

    return response.toString();
  }

  Future<List<Map<String, dynamic>>> getLogsForDate(
    DateTime date,
  ) async {
    final response = await _client
        .from('daily_sodium_logs')
        .select()
        .eq('user_id', _currentUserId)
        .eq('log_date', _formatDate(date))
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getTodayLogs() {
    return getLogsForDate(philippineNow);
  }

  Future<int> getTotalSodiumForDate(DateTime date) async {
    final logs = await getLogsForDate(date);

    var total = 0;

    for (final log in logs) {
      final value = log['sodium_amount'];

      if (value is num) {
        total += value.toInt();
      }
    }

    return total;
  }

  Future<int> getTodayTotalSodium() async {
    final logs = await getTodayLogs();

    var total = 0;

    for (final log in logs) {
      final value = log['sodium_amount'];

      if (value is num) {
        total += value.toInt();
      }
    }

    return total;
  }

  Future<void> updateFoodLog({
    required String logId,
    required String foodName,
    required int sodiumAmount,
    required double servings,
    int? sodiumPerServingMg,
  }) async {
    if (foodName.trim().isEmpty) {
      throw Exception('Food name is required.');
    }

    if (sodiumAmount < 0) {
      throw Exception('Sodium cannot be negative.');
    }

    if (servings <= 0) {
      throw Exception('Servings must be greater than zero.');
    }

    await _client
        .from('daily_sodium_logs')
        .update({
          'food_name': foodName.trim(),
          'sodium_amount': sodiumAmount,
          'servings': servings,
          'sodium_per_serving_mg': sodiumPerServingMg,
        })
        .eq('id', logId)
        .eq('user_id', _currentUserId);
  }

  Future<void> deleteFoodLog(String logId) async {
    await _client
        .from('daily_sodium_logs')
        .delete()
        .eq('id', logId)
        .eq('user_id', _currentUserId);
  }
}
