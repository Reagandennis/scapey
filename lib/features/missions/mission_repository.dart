import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mission_model.dart';

class MissionRepository {
  final SupabaseClient _client;
  MissionRepository(this._client);

  Future<List<Mission>> getMissions({String? status, String? priority}) async {
    try {
      final filters = <String, String>{};
      if (status != null) filters['status'] = status;
      if (priority != null) filters['priority'] = priority;

      var query = _client.from('missions').select();
      if (filters.isNotEmpty) query = query.match(filters);
      final data = await query
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8), onTimeout: () {
        // ignore: avoid_print
        print('Warning: Mission fetch timed out. Returning empty list.');
        return [];
      });
      return (data as List)
          .map((m) => Mission.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching missions: $e');
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
      // Fallback for cases where select is blocked by RLS but insert succeeded
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

final missionsProvider =
    FutureProvider.family<List<Mission>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repo = ref.watch(missionRepositoryProvider);
      return repo.getMissions(
        status: filters['status'],
        priority: filters['priority'],
      );
    });

final subtasksProvider = FutureProvider.family<List<MissionSubtask>, String>((
  ref,
  missionId,
) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.getSubtasks(missionId);
});
