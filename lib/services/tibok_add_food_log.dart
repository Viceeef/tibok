import 'package:supabase_flutter/supabase_flutter.dart';

class FoodLogService {
  FoodLogService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<String> addFoodLog({
    required String requestId,
    required String foodName,
    required int sodiumAmount,
    required DateTime logDate,
    required String entryType,
    String? sourceBarcode,
    double servings = 1,
    int? sodiumPerServingMg,
  }) async {
    if (_client.auth.currentUser == null) {
      throw Exception('You must be logged in to save a food entry.');
    }

    final response = await _client.rpc(
      'tibok_add_food_log',
      params: {
        'p_request_id': requestId,
        'p_food_name': foodName.trim(),
        'p_sodium_amount': sodiumAmount,
        'p_log_date': _formatDate(logDate),
        'p_entry_type': entryType,
        'p_source_barcode': sourceBarcode,
        'p_servings': servings,
        'p_sodium_per_serving': sodiumPerServingMg,
      },
    );

    if (response == null) {
      throw Exception('Food log could not be confirmed.');
    }

    return response.toString();
  }

  Future<List<Map<String, dynamic>>> getLogsForDate(
    DateTime date,
  ) async {
    final userId = currentUserId;

    if (userId == null) {
      throw Exception('You must be logged in.');
    }

    final response = await _client
        .from('daily_sodium_log')
        .select()
        .eq('user_id', userId)
        .eq('log_date', _formatDate(date))
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> getTotalSodiumForDate(
    DateTime date,
  ) async {
    final logs = await getLogsForDate(date);

    var total = 0;

    for (final log in logs) {
      final value = log['sodium_amount'];

      if (value is int) {
        total += value;
      } else if (value is num) {
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
    final userId = currentUserId;

    if (userId == null) {
      throw Exception('You must be logged in.');
    }

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
        .from('daily_sodium_log')
        .update({
          'food_name': foodName.trim(),
          'sodium_amount': sodiumAmount,
          'servings': servings,
          'sodium_per_serving_mg': sodiumPerServingMg,
        })
        .eq('id', logId)
        .eq('user_id', userId);
  }

  Future<void> deleteFoodLog(String logId) async {
    final userId = currentUserId;

    if (userId == null) {
      throw Exception('You must be logged in.');
    }

    await _client
        .from('daily_sodium_log')
        .delete()
        .eq('id', logId)
        .eq('user_id', userId);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
