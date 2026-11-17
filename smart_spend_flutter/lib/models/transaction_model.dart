class TransactionModel {
  final String id;
  final String? userId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String type; // 'INCOME' | 'EXPENSE'
  final String? icon;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.icon,
    this.createdAt,
  });

  bool get isIncome => type == 'INCOME';
  bool get isExpense => type == 'EXPENSE';

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? type,
    String? icon,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'icon': icon,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Map suitable for Supabase upsert/insert
  Map<String, dynamic> toRemoteMap({String? currentUserId}) {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'icon': icon,
    };
    if (userId != null || currentUserId != null) {
      map['user_id'] = userId ?? currentUserId;
    }
    return map;
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: (map['type']?.toString().toUpperCase() == 'INCOME')
          ? 'INCOME'
          : 'EXPENSE',
      icon: map['icon']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}
