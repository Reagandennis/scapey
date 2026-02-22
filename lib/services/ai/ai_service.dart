import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models
class MissionPlanResult {
  final String missionTitle;
  final String missionDescription;
  final String priority;
  final int estimatedMinutes;
  final List<String> subtasks;

  const MissionPlanResult({
    required this.missionTitle,
    required this.missionDescription,
    required this.priority,
    required this.estimatedMinutes,
    required this.subtasks,
  });

  factory MissionPlanResult.fromMap(Map<String, dynamic> map) {
    final subtasksList = map['subtasks'];
    return MissionPlanResult(
      missionTitle: map['mission_title'] as String? ?? 'Untitled',
      missionDescription: map['mission_description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'medium',
      estimatedMinutes: map['estimated_minutes'] as int? ?? 60,
      subtasks: subtasksList is List ? subtasksList.map((e) => e.toString()).toList() : [],
    );
  }
}

class NebulaResult {
  final String summary;
  final List<String> steps;
  final List<String> risks;
  final String timeline;
  final String? revenueModel;

  const NebulaResult({
    required this.summary,
    required this.steps,
    required this.risks,
    required this.timeline,
    this.revenueModel,
  });

  factory NebulaResult.fromMap(Map<String, dynamic> map) {
    List<String> _asList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : [];
    return NebulaResult(
      summary: map['summary'] as String? ?? '',
      steps: _asList(map['steps']),
      risks: _asList(map['risks']),
      timeline: map['timeline'] as String? ?? '',
      revenueModel: map['revenue_model'] as String?,
    );
  }
}

// Service
class AiService {
  final SupabaseClient _client;
  AiService(this._client);

  Future<MissionPlanResult> planMission(String idea) async {
    final response = await _client.functions.invoke(
      'ai_mission_plan',
      body: {'idea': idea},
    );
    if (response.data == null) throw Exception('AI service returned empty response');
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('error')) throw Exception(data['error']);
    return MissionPlanResult.fromMap(data);
  }

  Future<NebulaResult> structureNebula(String rawInput) async {
    final response = await _client.functions.invoke(
      'ai_nebula_structurer',
      body: {'raw_input': rawInput},
    );
    if (response.data == null) throw Exception('AI service returned empty response');
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('error')) throw Exception(data['error']);
    return NebulaResult.fromMap(data);
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(Supabase.instance.client);
});
