import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mission_repository.dart';

class MissionForm extends ConsumerStatefulWidget {
  final String? missionId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialPriority;
  final int? initialMinutes;

  const MissionForm({
    super.key,
    this.missionId,
    this.initialTitle,
    this.initialDescription,
    this.initialPriority,
    this.initialMinutes,
  });

  @override
  ConsumerState<MissionForm> createState() => _MissionFormState();
}

class _MissionFormState extends ConsumerState<MissionForm> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _minutesController = TextEditingController();
  String _priority = 'medium';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descController.text = widget.initialDescription ?? '';
    _minutesController.text = widget.initialMinutes?.toString() ?? '';
    _priority = widget.initialPriority ?? 'medium';
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final repo = ref.read(missionRepositoryProvider);
    try {
      final fields = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'priority': _priority,
        'estimated_minutes': _minutesController.text.isEmpty ? null : int.tryParse(_minutesController.text),
      };
      if (widget.missionId != null) {
        await repo.updateMission(widget.missionId!, fields).timeout(const Duration(seconds: 10));
      } else {
        await repo.createMission(fields).timeout(const Duration(seconds: 10));
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is TimeoutException ? 'Request timed out. Please check your connection.' : 'Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.missionId != null ? 'Edit Mission' : 'New Mission',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Mission Title'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutesController,
            decoration: const InputDecoration(labelText: 'Estimated minutes'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            dropdownColor: const Color(0xFF1E1E2E),
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'high', child: Text('High')),
            ],
            onChanged: _isLoading ? null : (v) => setState(() => _priority = v ?? 'medium'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.missionId != null ? 'Update Mission' : 'Launch Mission'),
          ),
        ],
      ),
    );
  }
}
