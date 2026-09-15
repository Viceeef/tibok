import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ResourceService {
  ResourceService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String get _currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in.');
    }

    return user.id;
  }

  Future<List<Map<String, dynamic>>> getResources() async {
    final response = await _client
        .from('resources')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Set<String>> getSavedResourceIds() async {
    final response = await _client
        .from('saved_resources')
        .select('resource_id')
        .eq('user_id', _currentUserId);

    final rows = List<Map<String, dynamic>>.from(response);

    return rows
        .map((row) => row['resource_id']?.toString())
        .whereType<String>()
        .toSet();
  }

  Future<void> saveResource(String resourceId) async {
    await _client.from('saved_resources').insert({
      'user_id': _currentUserId,
      'resource_id': resourceId,
    });
  }

  Future<void> removeSavedResource(String resourceId) async {
    await _client
        .from('saved_resources')
        .delete()
        .eq('user_id', _currentUserId)
        .eq('resource_id', resourceId);
  }

  Future<bool> toggleBookmark({
    required String resourceId,
    required bool currentlySaved,
  }) async {
    if (currentlySaved) {
      await removeSavedResource(resourceId);
      return false;
    }

    await saveResource(resourceId);
    return true;
  }
}
