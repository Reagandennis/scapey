class Mission {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String priority; // low, medium, high
  final String status;   // pending, active, complete
  final int? estimatedMinutes;
  final String? planetId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Mission({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.estimatedMinutes,
    this.planetId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: map['priority'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'pending',
      estimatedMinutes: map['estimated_minutes'] as int?,
      planetId: map['planet_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'estimated_minutes': estimatedMinutes,
      'planet_id': planetId,
    };
  }

  Mission copyWith({
    String? title, String? description, String? priority,
    String? status, int? estimatedMinutes, String? planetId,
  }) {
    return Mission(
      id: id, userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      planetId: planetId ?? this.planetId,
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }
}

class MissionSubtask {
  final String id;
  final String missionId;
  final String userId;
  final String title;
  final bool isDone;
  final int sortOrder;
  final DateTime createdAt;

  const MissionSubtask({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.title,
    required this.isDone,
    required this.sortOrder,
    required this.createdAt,
  });

  factory MissionSubtask.fromMap(Map<String, dynamic> map) {
    return MissionSubtask(
      id: map['id'] as String,
      missionId: map['mission_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      isDone: map['is_done'] as bool? ?? false,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
