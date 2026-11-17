class GoalModel {
  final String id;
  final String? userId;
  final String name;
  final double target;
  final double saved;
  final String targetDate;
  final String color;
  final DateTime? createdAt;

  GoalModel({
    required this.id,
    this.userId,
    required this.name,
    required this.target,
    this.saved = 0,
    required this.targetDate,
    this.color = 'primary',
    this.createdAt,
  });

  int get percentage =>
      target > 0 ? ((saved / target) * 100).clamp(0, 100).round() : 0;

  GoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? target,
    double? saved,
    String? targetDate,
    String? color,
    DateTime? createdAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      target: target ?? this.target,
      saved: saved ?? this.saved,
      targetDate: targetDate ?? this.targetDate,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'target': target,
      'saved': saved,
      'target_date': targetDate,
      'color': color,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toRemoteMap({String? currentUserId}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'target': target,
      'saved': saved,
      'target_date': targetDate,
      'color': color,
    };
    if (userId != null || currentUserId != null) {
      map['user_id'] = userId ?? currentUserId;
    }
    return map;
  }

  factory GoalModel.fromMap(Map<dynamic, dynamic> map) {
    return GoalModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      name: map['name']?.toString() ?? '',
      target: (map['target'] is num)
          ? (map['target'] as num).toDouble()
          : double.tryParse(map['target']?.toString() ?? '0') ?? 0.0,
      saved: (map['saved'] is num)
          ? (map['saved'] as num).toDouble()
          : double.tryParse(map['saved']?.toString() ?? '0') ?? 0.0,
      targetDate: map['target_date']?.toString() ?? '',
      color: map['color']?.toString() ?? 'primary',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}
