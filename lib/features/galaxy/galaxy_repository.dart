import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Galaxy {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime createdAt;

  const Galaxy({required this.id, required this.userId, required this.title, this.description, required this.createdAt});

  factory Galaxy.fromMap(Map<String, dynamic> m) => Galaxy(
    id: m['id'] as String, userId: m['user_id'] as String, title: m['title'] as String,
    description: m['description'] as String?, createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class SolarSystem {
  final String id;
  final String galaxyId;
  final String title;
  final String? description;

  const SolarSystem({required this.id, required this.galaxyId, required this.title, this.description});

  factory SolarSystem.fromMap(Map<String, dynamic> m) => SolarSystem(
    id: m['id'] as String, galaxyId: m['galaxy_id'] as String,
    title: m['title'] as String, description: m['description'] as String?,
  );
}

class Planet {
  final String id;
  final String solarSystemId;
  final String title;
  final String? description;

  const Planet({required this.id, required this.solarSystemId, required this.title, this.description});

  factory Planet.fromMap(Map<String, dynamic> m) => Planet(
    id: m['id'] as String, solarSystemId: m['solar_system_id'] as String,
    title: m['title'] as String, description: m['description'] as String?,
  );
}

class GalaxyRepository {
  final SupabaseClient _client;
  GalaxyRepository(this._client);

  Future<List<Galaxy>> getGalaxies() async {
    final data = await _client.from('galaxies').select().order('created_at');
    return (data as List).map((e) => Galaxy.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<SolarSystem>> getSolarSystems(String galaxyId) async {
    final data = await _client.from('solar_systems').select().eq('galaxy_id', galaxyId);
    return (data as List).map((e) => SolarSystem.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<Planet>> getPlanets(String solarSystemId) async {
    final data = await _client.from('planets').select().eq('solar_system_id', solarSystemId);
    return (data as List).map((e) => Planet.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Galaxy> createGalaxy(String title, String? description) async {
    final data = await _client.from('galaxies').insert({
      'user_id': _client.auth.currentUser!.id, 'title': title, 'description': description,
    }).select().single();
    return Galaxy.fromMap(data);
  }
}

final galaxyRepositoryProvider = Provider<GalaxyRepository>((ref) {
  return GalaxyRepository(Supabase.instance.client);
});

final galaxiesProvider = FutureProvider<List<Galaxy>>((ref) async {
  return ref.watch(galaxyRepositoryProvider).getGalaxies();
});

final solarSystemsProvider = FutureProvider.family<List<SolarSystem>, String>((ref, galaxyId) async {
  return ref.watch(galaxyRepositoryProvider).getSolarSystems(galaxyId);
});
