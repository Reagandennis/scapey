import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'nebula_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai/ai_service.dart';

class NebulaScreen extends ConsumerStatefulWidget {
  const NebulaScreen({super.key});

  @override
  ConsumerState<NebulaScreen> createState() => _NebulaScreenState();
}

class _NebulaScreenState extends ConsumerState<NebulaScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;
  NebulaEntry? _latestResult;

  Future<void> _submit() async {
    if (_inputController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _latestResult = null;
    });
    try {
      final ai = ref.read(aiServiceProvider);
      final repo = ref.read(nebulaRepositoryProvider);
      final result = await ai.structureNebula(_inputController.text.trim());
      final entry = await repo.saveEntry(
        rawInput: _inputController.text.trim(),
        summary: result.summary,
        steps: result.steps,
        risks: result.risks,
        timeline: result.timeline,
        revenueModel: result.revenueModel,
      );
      ref.invalidate(nebulaEntriesProvider);
      setState(() {
        _latestResult = entry;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(nebulaEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Idea Nebula')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brain Dump',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dump your raw idea. AI will structure it.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Type anything...'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Structure with AI'),
              ),
            ),
            if (_latestResult != null) ...[
              const SizedBox(height: 28),
              _NebulaResultCard(entry: _latestResult!),
            ],
            const SizedBox(height: 32),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            const Text(
              'History',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: Colors.redAccent)),
              data: (entries) {
                if (entries.isEmpty)
                  return const Text(
                    'No entries yet.',
                    style: TextStyle(color: Colors.grey),
                  );
                return Column(
                  children: entries
                      .map(
                        (e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            e.rawInput.length > 60
                                ? '${e.rawInput.substring(0, 60)}...'
                                : e.rawInput,
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            e.createdAt.toLocal().toString().substring(0, 16),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () => setState(() => _latestResult = e),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _NebulaBottomNav(),
    );
  }
}

class _NebulaResultCard extends StatelessWidget {
  final NebulaEntry entry;
  const _NebulaResultCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Summary', [entry.summary ?? '']),
          if (entry.steps.isNotEmpty)
            _buildSection('Execution Steps', entry.steps),
          if (entry.risks.isNotEmpty) _buildSection('Risks', entry.risks),
          if (entry.timeline != null && entry.timeline!.isNotEmpty)
            _buildSection('Timeline', [entry.timeline!]),
          if (entry.revenueModel != null && entry.revenueModel!.isNotEmpty)
            _buildSection('Revenue Model', [entry.revenueModel!]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('· ', style: TextStyle(color: AppTheme.primary)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.text,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NebulaBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1E1E2E),
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/focus');
            break;
          case 2:
            break; // already here
          case 3:
            context.go('/galaxy');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.rocket_launch),
          label: 'Missions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timer_outlined),
          label: 'Focus',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud_circle_outlined),
          label: 'Nebula',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Galaxy',
        ),
      ],
    );
  }
}
