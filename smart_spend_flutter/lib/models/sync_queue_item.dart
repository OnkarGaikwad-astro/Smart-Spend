import 'dart:convert';

class SyncQueueItem {
  final String id;
  final String table;
  final String action; // 'insert', 'update', 'delete'
  final String recordId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.table,
    required this.action,
    required this.recordId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncQueueItem copyWith({
    String? id,
    String? table,
    String? action,
    String? recordId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      table: table ?? this.table,
      action: action ?? this.action,
      recordId: recordId ?? this.recordId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table': table,
      'action': action,
      'record_id': recordId,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory SyncQueueItem.fromMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic> parsedData = {};
    if (map['data'] != null) {
      if (map['data'] is String) {
        try {
          parsedData = Map<String, dynamic>.from(jsonDecode(map['data']));
        } catch (_) {}
      } else if (map['data'] is Map) {
        parsedData = Map<String, dynamic>.from(map['data']);
      }
    }

    return SyncQueueItem(
      id: map['id']?.toString() ?? '',
      table: map['table']?.toString() ?? '',
      action: map['action']?.toString() ?? 'insert',
      recordId: map['record_id']?.toString() ?? '',
      data: parsedData,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      retryCount: (map['retry_count'] is num)
          ? (map['retry_count'] as num).toInt()
          : 0,
    );
  }
}
