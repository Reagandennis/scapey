import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'galaxy_repository.dart';
import '../../core/theme/app_theme.dart';

class GalaxyMapScreen extends ConsumerWidget {
  const GalaxyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galaxiesAsync = ref.watch(galaxiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Galaxy Map')),
      body: galaxiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
        data: (galaxies) {
          if (galaxies.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No galaxies yet, Commander.', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Create a galaxy to start your map.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            );
          }
          return InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.3,
            maxScale: 3.0,
            child: SizedBox(
              width: 1200,
              height: 900,
              child: _GalaxyCanvas(galaxies: galaxies),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showCreateGalaxyDialog(context, ref),
      ),
      bottomNavigationBar: _GalaxyBottomNav(),
    );
  }

  void _showCreateGalaxyDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('New Galaxy'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Galaxy name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ref.read(galaxyRepositoryProvider).createGalaxy(ctrl.text.trim(), null);
                ref.invalidate(galaxiesProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _GalaxyCanvas extends ConsumerStatefulWidget {
  final List<Galaxy> galaxies;
  const _GalaxyCanvas({required this.galaxies});

  @override
  ConsumerState<_GalaxyCanvas> createState() => _GalaxyCanvasState();
}

class _GalaxyCanvasState extends ConsumerState<_GalaxyCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _rand = Random(7);
  late List<Offset> _galaxyPositions;
  Galaxy? _selectedGalaxy;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _galaxyPositions = List.generate(widget.galaxies.length, (i) {
      return Offset(200 + _rand.nextDouble() * 800, 100 + _rand.nextDouble() * 700);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return GestureDetector(
          onTapDown: (details) {
            for (int i = 0; i < _galaxyPositions.length; i++) {
              final pos = _galaxyPositions[i];
              if ((details.localPosition - pos).distance < 40) {
                setState(() => _selectedGalaxy = widget.galaxies[i]);
                _showGalaxyDetail(widget.galaxies[i]);
                return;
              }
            }
            setState(() => _selectedGalaxy = null);
          },
          child: CustomPaint(
            painter: _GalaxyMapPainter(
              galaxies: widget.galaxies,
              positions: _galaxyPositions,
              pulse: _pulseController.value,
              selected: _selectedGalaxy,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  void _showGalaxyDetail(Galaxy galaxy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.circle, color: AppTheme.primary, size: 12),
            const SizedBox(width: 8),
            Text(galaxy.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          if (galaxy.description != null) ...[
            const SizedBox(height: 8),
            Text(galaxy.description!, style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.explore_outlined),
            label: const Text('View Solar Systems'),
          ),
        ]),
      ),
    );
  }
}

class _GalaxyMapPainter extends CustomPainter {
  final List<Galaxy> galaxies;
  final List<Offset> positions;
  final double pulse;
  final Galaxy? selected;

  static final _rand = Random(42);
  static final _starPositions = List.generate(200, (_) => Offset(_rand.nextDouble(), _rand.nextDouble()));
  static final _starSizes = List.generate(200, (_) => _rand.nextDouble() * 1.5 + 0.5);

  _GalaxyMapPainter({
    required this.galaxies, required this.positions,
    required this.pulse, this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.background,
    );

    // Stars
    final starPaint = Paint();
    for (int i = 0; i < _starPositions.length; i++) {
      starPaint.color = Colors.white.withOpacity(0.2 + 0.3 * ((i % 5) / 5));
      canvas.drawCircle(
        Offset(_starPositions[i].dx * size.width, _starPositions[i].dy * size.height),
        _starSizes[i], starPaint,
      );
    }

    // Galaxy nodes
    for (int i = 0; i < galaxies.length; i++) {
      if (i >= positions.length) break;
      final pos = positions[i];
      final galaxy = galaxies[i];
      final isSelected = selected?.id == galaxy.id;

      // Outer glow ring (pulsing)
      final glowRadius = 36.0 + pulse * 8;
      canvas.drawCircle(pos, glowRadius, Paint()
        ..color = AppTheme.primary.withOpacity(0.08 + pulse * 0.06)
        ..style = PaintingStyle.fill);

      // Ring
      canvas.drawCircle(pos, 28, Paint()
        ..color = isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 1.5);

      // Center dot
      canvas.drawCircle(pos, isSelected ? 18 : 14, Paint()
        ..color = isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.7)
        ..style = PaintingStyle.fill);

      // Galaxy icon approximation (spiral dots)
      for (int j = 0; j < 8; j++) {
        final angle = j * pi / 4;
        final r = 6.0 + j * 0.5;
        final sp = Offset(pos.dx + cos(angle) * r * 0.6, pos.dy + sin(angle) * r * 0.6);
        canvas.drawCircle(sp, 1.5, Paint()..color = Colors.white.withOpacity(0.5));
      }

      // Label
      final tp = TextPainter(
        text: TextSpan(text: galaxy.title, style: TextStyle(
          color: isSelected ? AppTheme.accent : AppTheme.text,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + 34));
    }
  }

  @override
  bool shouldRepaint(_GalaxyMapPainter old) =>
      old.pulse != pulse || old.selected?.id != selected?.id;
}

class _GalaxyBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1E1E2E),
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        switch (i) {
          case 0: Navigator.of(context).pushReplacementNamed('/'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.rocket_launch), label: 'Missions'),
        BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: 'Focus'),
        BottomNavigationBarItem(icon: Icon(Icons.cloud_circle_outlined), label: 'Nebula'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Galaxy'),
      ],
    );
  }
}
