import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mission_repository.dart';
import 'mission_model.dart';
import 'mission_form.dart';
import 'mission_detail_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/spacey_bottom_nav.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  String? _filterStatus;
  String? _filterPriority;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['user_name'] ?? 'Commander';
    final avatarUrl = user?.userMetadata?['avatar_url'];
    final missionsAsync = ref.watch(
      missionsProvider({'status': _filterStatus, 'priority': _filterPriority}),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome back, $userName'),
        actions: [
          PopupMenuButton(
            onSelected: (value) async {
              final router = GoRouter.of(context);
              if (value == 'profile') {
                router.go('/profile');
              } else if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                router.go('/auth');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Update Profile'),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            child: CircleAvatar(
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(userName.substring(0, 1).toUpperCase())
                  : null,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            currentStatus: _filterStatus,
            currentPriority: _filterPriority,
            onStatusChanged: (v) => setState(() => _filterStatus = v),
            onPriorityChanged: (v) => setState(() => _filterPriority = v),
          ),
          Expanded(
            child: missionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error loading missions: $e',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (missions) {
                if (missions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No missions yet, Commander.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap + to create your first mission.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: missions.length,
                  itemBuilder: (context, i) =>
                      _MissionTile(mission: missions[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1E1E2E),
            builder: (_) => const MissionForm(),
          );
          ref.invalidate(missionsProvider);
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const SpaceyBottomNav(currentIndex: 0),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? currentStatus;
  final String? currentPriority;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;

  const _FilterBar({
    required this.currentStatus,
    required this.currentPriority,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          buildChip('All', currentStatus == null, () => onStatusChanged(null)),
          const SizedBox(width: 8),
          buildChip(
            'Pending',
            currentStatus == 'pending',
            () => onStatusChanged('pending'),
          ),
          const SizedBox(width: 8),
          buildChip(
            'Active',
            currentStatus == 'active',
            () => onStatusChanged('active'),
          ),
          const SizedBox(width: 8),
          buildChip(
            'Done',
            currentStatus == 'complete',
            () => onStatusChanged('complete'),
          ),
        ],
      ),
    );
  }

  Widget buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
        ),
        backgroundColor: selected ? AppTheme.primary : const Color(0xFF1E1E2E),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _MissionTile extends ConsumerWidget {
  final Mission mission;
  const _MissionTile({required this.mission});

  Color get _priorityColor {
    switch (mission.priority) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return AppTheme.accent;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isComplete = mission.status == 'complete';
    return Card(
      color: const Color(0xFF1E1E2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(radius: 6, backgroundColor: _priorityColor),
        title: Text(
          mission.title,
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w600,
            decoration: isComplete ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: mission.estimatedMinutes != null
            ? Text(
                '${mission.estimatedMinutes} min · ${mission.priority}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            : null,
        trailing: Checkbox(
          value: isComplete,
          activeColor: AppTheme.primary,
          onChanged: (v) async {
            await ref.read(missionRepositoryProvider).updateMission(
              mission.id,
              {'status': v == true ? 'complete' : 'pending'},
            );
            ref.invalidate(missionsProvider);
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MissionDetailScreen(mission: mission),
            ),
          );
        },
      ),
    );
  }
}
