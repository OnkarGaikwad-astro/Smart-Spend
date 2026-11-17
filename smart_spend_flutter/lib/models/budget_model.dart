class BudgetModel {
  final String id;
  final String? userId;
  final String category;
  final double allocated;
  final double spent;
  final String icon;
  final String color;
  final DateTime? createdAt;

  BudgetModel({
    required this.id,
    this.userId,
    required this.category,
    required this.allocated,
    this.spent = 0,
    required this.icon,
    this.color = 'primary',
    this.createdAt,
  });

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    double? allocated,
    double? spent,
    String? icon,
    String? color,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      allocated: allocated ?? this.allocated,
      spent: spent ?? this.spent,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'category': category,
      'allocated': allocated,
      'spent': spent,
      'icon': icon,
      'color': color,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toRemoteMap({String? currentUserId}) {
    final map = <String, dynamic>{
      'id': id,
      'category': category,
      'allocated': allocated,
      'spent': spent,
      'icon': icon,
      'color': color,
    };
    if (userId != null || currentUserId != null) {
      map['user_id'] = userId ?? currentUserId;
    }
    return map;
  }

  factory BudgetModel.fromMap(Map<dynamic, dynamic> map) {
    return BudgetModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      category: map['category']?.toString() ?? '',
      allocated: (map['allocated'] is num)
          ? (map['allocated'] as num).toDouble()
          : double.tryParse(map['allocated']?.toString() ?? '0') ?? 0.0,
      spent: (map['spent'] is num)
          ? (map['spent'] as num).toDouble()
          : double.tryParse(map['spent']?.toString() ?? '0') ?? 0.0,
      icon: map['icon']?.toString() ?? '🎯',
      color: map['color']?.toString() ?? 'primary',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}
