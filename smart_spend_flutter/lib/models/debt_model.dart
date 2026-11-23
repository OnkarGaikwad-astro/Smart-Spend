class DebtEntry {
  final String id;
  final String? debtId;
  final double amount;
  final String type; // 'LENT', 'BORROWED', or 'REPAID'
  final String note;
  final DateTime date;

  DebtEntry({
    required this.id,
    this.debtId,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
  });

  DebtEntry copyWith({
    String? id,
    String? debtId,
    double? amount,
    String? type,
    String? note,
    DateTime? date,
  }) {
    return DebtEntry(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (debtId != null) 'debt_id': debtId,
      'amount': amount,
      'type': type,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  Map<String, dynamic> toRemoteMap({String? currentUserId}) {
    final map = <String, dynamic>{
      'id': id,
      'amount': amount,
      'type': type,
      'note': note,
      'date': date.toIso8601String(),
    };
    if (debtId != null) map['debt_id'] = debtId;
    if (currentUserId != null) map['user_id'] = currentUserId;
    return map;
  }

  factory DebtEntry.fromMap(Map<dynamic, dynamic> map) {
    return DebtEntry(
      id: map['id']?.toString() ?? '',
      debtId: map['debt_id']?.toString(),
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      type: map['type']?.toString().toUpperCase() ?? 'LENT',
      note: map['note']?.toString() ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class DebtModel {
  final String id;
  final String? userId;
  final String personName;
  final String? phoneNumber;
  final String type; // 'LENT' (They owe me / You'll Get) or 'BORROWED' (I owe them / You'll Give)
  final List<DebtEntry> entries;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtModel({
    required this.id,
    this.userId,
    required this.personName,
    this.phoneNumber,
    this.type = 'LENT',
    this.entries = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLent => type == 'LENT';
  bool get isBorrowed => type == 'BORROWED';

  /// Total outstanding amount
  double get totalOwed {
    double total = 0.0;
    for (final entry in entries) {
      if (entry.type == 'LENT' || entry.type == 'BORROWED') {
        total += entry.amount;
      } else if (entry.type == 'REPAID') {
        total -= entry.amount;
      }
    }
    return total < 0 ? 0.0 : total;
  }

  /// Total principal amount ever lent or borrowed
  double get totalPrincipal {
    double total = 0.0;
    for (final entry in entries) {
      if (entry.type == 'LENT' || entry.type == 'BORROWED') {
        total += entry.amount;
      }
    }
    return total;
  }

  /// Total amount repaid
  double get totalRepaid {
    double total = 0.0;
    for (final entry in entries) {
      if (entry.type == 'REPAID') {
        total += entry.amount;
      }
    }
    return total;
  }

  bool get isSettled => totalOwed <= 0 && entries.isNotEmpty;

  /// Most recent note/reason
  String get lastNote {
    if (entries.isEmpty) return 'No notes';
    final sorted = List<DebtEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.note.isEmpty
        ? (isLent ? 'Lent money' : 'Borrowed money')
        : sorted.first.note;
  }

  /// Most recent activity date
  DateTime get lastActivityDate {
    if (entries.isEmpty) return updatedAt;
    final sorted = List<DebtEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.date;
  }

  DebtModel copyWith({
    String? id,
    String? userId,
    String? personName,
    String? phoneNumber,
    String? type,
    List<DebtEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      type: type ?? this.type,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'person_name': personName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'type': type,
      'entries': entries.map((e) => e.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toRemoteMap({String? currentUserId}) {
    final map = <String, dynamic>{
      'id': id,
      'person_name': personName,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (phoneNumber != null) map['phone_number'] = phoneNumber;
    if (userId != null || currentUserId != null) {
      map['user_id'] = userId ?? currentUserId;
    }
    return map;
  }

  factory DebtModel.fromMap(Map<dynamic, dynamic> map) {
    final rawEntries = map['entries'];
    List<DebtEntry> parsedEntries = [];
    if (rawEntries is List) {
      for (final item in rawEntries) {
        if (item is Map) {
          parsedEntries.add(DebtEntry.fromMap(item));
        }
      }
    }

    final rawType = map['type']?.toString().toUpperCase();
    final type = (rawType == 'BORROWED') ? 'BORROWED' : 'LENT';

    return DebtModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      personName: map['person_name']?.toString() ?? 'Unknown',
      phoneNumber: map['phone_number']?.toString(),
      type: type,
      entries: parsedEntries,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
