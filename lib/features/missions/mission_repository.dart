import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mission_model.dart';

class MissionRepository {
  final SupabaseClient _client;
  MissionRepository(this._client);

  Future<List<Mission>> getMissions({String? status, String? priority}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      print('[getMissions] No active user session. Returning empty list.');
      return [];
    }

    print(
      '[getMissions] Fetching from Supabase... (status: $status, priority: $priority)',
    );
    try {
      var query = _client.from('missions').select();
      if (status != null) query = query.eq('status', status);
      if (priority != null) query = query.eq('priority', priority);

      final data = await query
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      final missions = (data as List)
          .map((m) => Mission.fromMap(m as Map<String, dynamic>))
          .toList();
      print('[getMissions] Success! Loaded ${missions.length} missions.');
      return missions;
    } catch (e) {
      print('[getMissions] Error/Timeout: $e');
      return [];
    }
  }

  Future<Mission> createMission(Map<String, dynamic> fields) async {
    final response = await _client
        .from('missions')
        .insert({...fields, 'user_id': _client.auth.currentUser!.id})
        .select()
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (response == null) {
      return Mission(
        id: '',
        userId: _client.auth.currentUser!.id,
        title: fields['title'],
        description: fields['description'],
        priority: fields['priority'] ?? 'medium',
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return Mission.fromMap(response);
  }

  Future<Mission> updateMission(String id, Map<String, dynamic> fields) async {
    final data = await _client
        .from('missions')
        .update(fields)
        .eq('id', id)
        .select()
        .single()
        .timeout(const Duration(seconds: 10));
    return Mission.fromMap(data);
  }

  Future<void> deleteMission(String id) async {
    await _client
        .from('missions')
        .delete()
        .eq('id', id)
        .timeout(const Duration(seconds: 10));
  }

  Future<List<MissionSubtask>> getSubtasks(String missionId) async {
    final data = await _client
        .from('mission_subtasks')
        .select()
        .eq('mission_id', missionId)
        .order('sort_order');
    return (data as List)
        .map((s) => MissionSubtask.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  Future<MissionSubtask> createSubtask({
    required String missionId,
    required String title,
    required int sortOrder,
  }) async {
    final data = await _client
        .from('mission_subtasks')
        .insert({
          'mission_id': missionId,
          'user_id': _client.auth.currentUser!.id,
          'title': title,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    return MissionSubtask.fromMap(data);
  }

  Future<void> toggleSubtask(String subtaskId, bool isDone) async {
    await _client
        .from('mission_subtasks')
        .update({'is_done': isDone})
        .eq('id', subtaskId);
  }

  Future<void> reorderSubtask(String subtaskId, int sortOrder) async {
    await _client
        .from('mission_subtasks')
        .update({'sort_order': sortOrder})
        .eq('id', subtaskId);
  }
}

// Providers
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository(Supabase.instance.client);
});

// Using a Record for the family key to ensure value-based equality and avoid infinite loops
typedef MissionFilters = ({String? status, String? priority});

final missionsProvider = FutureProvider.family<List<Mission>, MissionFilters>((
  ref,
  filters,
) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getMissions(status: filters.status, priority: filters.priority);
});

final subtasksProvider = FutureProvider.family<List<MissionSubtask>, String>((
  ref,
  missionId,
) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getSubtasks(missionId);
});
