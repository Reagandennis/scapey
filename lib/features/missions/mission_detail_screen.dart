import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mission_model.dart';
import 'mission_repository.dart';
import 'mission_form.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai/ai_service.dart';

class MissionDetailScreen extends ConsumerStatefulWidget {
  final Mission mission;
  const MissionDetailScreen({super.key, required this.mission});

  @override
  ConsumerState<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends ConsumerState<MissionDetailScreen> {
  late Mission _mission;
  final _aiController = TextEditingController();
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
  }

  Future<void> _runAiPlan() async {
    if (_aiController.text.trim().isEmpty) return;
    setState(() => _isAiLoading = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.planMission(_aiController.text.trim());
      final repo = ref.read(missionRepositoryProvider);

      // Save subtasks from AI
      for (int i = 0; i < result.subtasks.length; i++) {
        await repo.createSubtask(
          missionId: _mission.id,
          title: result.subtasks[i],
          sortOrder: i,
        );
      }
      ref.invalidate(subtasksProvider(_mission.id));
      if (mounted) {
        _aiController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI plan generated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  Future<void> _deleteMission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Delete Mission?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(missionRepositoryProvider).deleteMission(_mission.id);
      ref.invalidate(missionsProvider);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(subtasksProvider(_mission.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Brief'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: const Color(0xFF1E1E2E),
                builder: (_) => MissionForm(
                  missionId: _mission.id,
                  initialTitle: _mission.title,
                  initialDescription: _mission.description,
                  initialPriority: _mission.priority,
                  initialMinutes: _mission.estimatedMinutes,
                ),
              );
              ref.invalidate(missionsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteMission,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mission.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _Badge(_mission.priority, _priorityColor(_mission.priority)),
                const SizedBox(width: 8),
                _Badge(_mission.status, AppTheme.primary),
                if (_mission.estimatedMinutes != null) ...[
                  const SizedBox(width: 8),
                  _Badge('${_mission.estimatedMinutes} min', Colors.grey),
                ],
              ],
            ),
            if (_mission.description != null && _mission.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_mission.description!, style: const TextStyle(color: Colors.grey, height: 1.5)),
            ],
            const SizedBox(height: 28),
            const Text('AI Mission Planner', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
            const SizedBox(height: 8),
            TextField(
              controller: _aiController,
              decoration: const InputDecoration(hintText: 'Describe your idea...'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAiLoading ? null : _runAiPlan,
                icon: _isAiLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('AI Plan'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E2E)),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Subtasks', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            subtasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
              data: (subtasks) {
                if (subtasks.isEmpty) {
                  return const Text('No subtasks yet.', style: TextStyle(color: Colors.grey));
                }
                return Column(
                  children: subtasks.map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: s.isDone,
                      activeColor: AppTheme.primary,
                      onChanged: (v) async {
                        await ref.read(missionRepositoryProvider).toggleSubtask(s.id, v ?? false);
                        ref.invalidate(subtasksProvider(_mission.id));
                      },
                    ),
                    title: Text(s.title, style: TextStyle(
                      decoration: s.isDone ? TextDecoration.lineThrough : null,
                      color: s.isDone ? Colors.grey : AppTheme.text,
                    )),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                          onPressed: () => _editSubtask(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          onPressed: () async {
                            await ref.read(missionRepositoryProvider).deleteSubtask(s.id);
                            ref.invalidate(subtasksProvider(_mission.id));
                          },
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSubtask(MissionSubtask subtask) async {
    final controller = TextEditingController(text: subtask.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Edit Subtask'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Subtask title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != subtask.title) {
      await ref.read(missionRepositoryProvider).updateSubtask(subtask.id, newTitle);
      ref.invalidate(subtasksProvider(_mission.id));
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return Colors.redAccent;
      case 'medium': return AppTheme.accent;
      default: return Colors.green;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
