import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NebulaEntry {
  final String id;
  final String userId;
  final String rawInput;
  final String? summary;
  final List<String> steps;
  final List<String> risks;
  final String? timeline;
  final String? revenueModel;
  final DateTime createdAt;

  const NebulaEntry({
    required this.id, required this.userId, required this.rawInput,
    this.summary, required this.steps, required this.risks,
    this.timeline, this.revenueModel, required this.createdAt,
  });

  factory NebulaEntry.fromMap(Map<String, dynamic> m) {
    List<String> asList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : [];
    return NebulaEntry(
      id: m['id'] as String, userId: m['user_id'] as String,
      rawInput: m['raw_input'] as String,
      summary: m['summary'] as String?,
      steps: asList(m['steps']),
      risks: asList(m['risks']),
      timeline: m['timeline'] as String?,
      revenueModel: m['revenue_model'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

class NebulaRepository {
  final SupabaseClient _client;
  NebulaRepository(this._client);

  Future<List<NebulaEntry>> getEntries() async {
    final data = await _client.from('nebula_entries')
        .select().order('created_at', ascending: false);
    return (data as List).map((e) => NebulaEntry.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<NebulaEntry> saveEntry({
    required String rawInput, required String summary,
    required List<String> steps, required List<String> risks,
    required String timeline, String? revenueModel,
  }) async {
    final data = await _client.from('nebula_entries').insert({
      'user_id': _client.auth.currentUser!.id,
      'raw_input': rawInput, 'summary': summary,
      'steps': steps, 'risks': risks,
      'timeline': timeline, 'revenue_model': revenueModel,
    }).select().single();
    return NebulaEntry.fromMap(data);
  }
}

final nebulaRepositoryProvider = Provider<NebulaRepository>((ref) {
  return NebulaRepository(Supabase.instance.client);
});

final nebulaEntriesProvider = FutureProvider<List<NebulaEntry>>((ref) async {
  return ref.watch(nebulaRepositoryProvider).getEntries();
});
