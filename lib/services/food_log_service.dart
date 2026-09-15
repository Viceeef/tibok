import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_service.dart';

class FoodLogService {
  FoodLogService({
    SupabaseClient? client,
  }) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const Uuid _uuid = Uuid();

  DateTime get philippineNow => DateTime.now().toUtc().add(
        const Duration(hours: 8),
      );

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String createRequestId() {
    return _uuid.v4();
  }

  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
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

    // Existing scanner calls can omit this for now.
    // Unknown is safer than assigning a false nutrition basis.
    String sodiumBasis = 'unknown',
  }) async {
    if (foodName.trim().isEmpty) {
      throw Exception(
        'Food name cannot be empty.',
      );
    }

    if (sodiumAmount < 0) {
      throw Exception(
        'Sodium amount cannot be negative.',
      );
    }

    if (servings <= 0) {
      throw Exception(
        'Quantity must be greater than zero.',
      );
    }

    if (!const {
      'manual',
      'scanned',
      'searched',
    }.contains(entryType)) {
      throw Exception(
        'Invalid food entry type.',
      );
    }

    if (!const {
      'per_100g',
      'per_serving',
      'unknown',
    }.contains(sodiumBasis)) {
      throw Exception(
        'Invalid sodium basis.',
      );
    }

    final result = await _client.rpc(
      'tibok_add_food_log',
      params: {
        'p_request_id': requestId,
        'p_food_name': foodName.trim(),
        'p_sodium_amount': sodiumAmount,
        'p_log_date': _formatDate(
          logDate ?? philippineNow,
        ),
        'p_entry_type': entryType,
        'p_source_barcode': sourceBarcode,
        'p_servings': servings,
        'p_sodium_per_serving': sodiumPerServingMg,
        'p_sodium_basis': sodiumBasis,
      },
    );

    return result.toString();
  }

  Future<List<Map<String, dynamic>>> getLogsForDate(
    DateTime date,
  ) async {
    final response = await _client
        .from('daily_sodium_logs')
        .select()
        .eq(
          'user_id',
          _currentUserId,
        )
        .eq(
          'log_date',
          _formatDate(date),
        )
        .order(
          'created_at',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  Future<List<Map<String, dynamic>>> getTodayLogs() async {
    return getLogsForDate(
      philippineNow,
    );
  }

  Future<int> getTotalSodiumForDate(
    DateTime date,
  ) async {
    final logs = await getLogsForDate(date);

    var total = 0;

    for (final log in logs) {
      final amount = log['sodium_amount'];

      if (amount is num) {
        total += amount.toInt();
      }
    }

    return total;
  }

  Future<int> getTodayTotalSodium() async {
    return getTotalSodiumForDate(
      philippineNow,
    );
  }

  Future<void> updateFoodLog({
    required String logId,
    required String foodName,
    required int sodiumAmount,
    double? servings,
    int? sodiumPerServingMg,
    String? sodiumBasis,
  }) async {
    if (foodName.trim().isEmpty) {
      throw Exception(
        'Food name cannot be empty.',
      );
    }

    if (sodiumAmount < 0) {
      throw Exception(
        'Sodium amount cannot be negative.',
      );
    }

    if (servings != null && servings <= 0) {
      throw Exception(
        'Quantity must be greater than zero.',
      );
    }

    if (sodiumBasis != null &&
        !const {
          'per_100g',
          'per_serving',
          'unknown',
        }.contains(sodiumBasis)) {
      throw Exception(
        'Invalid sodium basis.',
      );
    }

    final updates = <String, dynamic>{
      'food_name': foodName.trim(),
      'sodium_amount': sodiumAmount,
    };

    if (servings != null) {
      updates['servings'] = servings;
    }

    if (sodiumPerServingMg != null) {
      updates['sodium_per_serving_mg'] = sodiumPerServingMg;
    }

    if (sodiumBasis != null) {
      updates['sodium_basis'] = sodiumBasis;
    }

    await _client
        .from('daily_sodium_logs')
        .update(updates)
        .eq(
          'id',
          logId,
        )
        .eq(
          'user_id',
          _currentUserId,
        );
  }

  Future<void> deleteFoodLog(
    String logId,
  ) async {
    await _client
        .from('daily_sodium_logs')
        .delete()
        .eq(
          'id',
          logId,
        )
        .eq(
          'user_id',
          _currentUserId,
        );
  }
}
