import 'dart:convert';
import '../../database_helper.dart';
import '../../../models/activity_log.dart';

/// Activity Log Data Access Object
/// Handles all activity logging and querying
class ActivityLogDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create activity log entry
  Future<ActivityLog> createLog(ActivityLog log) async {
    final db = await _dbHelper.database;
    await db.insert('activity_logs', {
      'id': log.id,
      'event_type': log.eventType.name,
      'entity_type': log.entityType.name,
      'entity_id': log.entityId,
      'description': log.description,
      'metadata': log.metadata != null ? jsonEncode(log.metadata) : null,
      'created_at': log.createdAt.toIso8601String(),
      'is_synced': log.isSynced ? 1 : 0,
    });
    return log;
  }

  // Get activity logs with filters
  Future<List<ActivityLog>> getLogs({
    ActivityEventType? eventType,
    ActivityEntityType? entityType,
    String? entityId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (eventType != null) {
      whereClause += ' AND event_type = ?';
      whereArgs.add(eventType.name);
    }

    if (entityType != null) {
      whereClause += ' AND entity_type = ?';
      whereArgs.add(entityType.name);
    }

    if (entityId != null) {
      whereClause += ' AND entity_id = ?';
      whereArgs.add(entityId);
    }

    if (fromDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(toDate.toIso8601String());
    }

    final maps = await db.query(
      'activity_logs',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map(_mapToActivityLog).toList();
  }

  // Get today's activity logs
  Future<List<ActivityLog>> getTodaysLogs() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return getLogs(fromDate: startOfDay, limit: 500);
  }

  // Get logs for a specific entity (e.g., order)
  Future<List<ActivityLog>> getLogsForEntity({
    required ActivityEntityType entityType,
    required String entityId,
  }) async {
    return getLogs(
      entityType: entityType,
      entityId: entityId,
      limit: 100,
    );
  }

  // Get unsynced logs
  Future<List<ActivityLog>> getUnsyncedLogs() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'activity_logs',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
      limit: 100,
    );
    return maps.map(_mapToActivityLog).toList();
  }

  // Mark logs as synced
  Future<void> markAsSynced(List<String> ids) async {
    final db = await _dbHelper.database;
    await db.update(
      'activity_logs',
      {'is_synced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // Clean up old logs (retention policy: 30 days)
  Future<int> cleanupOldLogs({int retentionDays = 30}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    return await db.delete(
      'activity_logs',
      where: 'created_at < ? AND is_synced = 1',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Get activity counts by type (for dashboard)
  Future<Map<ActivityEventType, int>> getEventCounts({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (fromDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(toDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT event_type, COUNT(*) as count 
      FROM activity_logs 
      WHERE $whereClause 
      GROUP BY event_type
    ''', whereArgs);

    Map<ActivityEventType, int> counts = {};
    for (final row in result) {
      final eventType = ActivityEventType.values.firstWhere(
        (e) => e.name == row['event_type'],
        orElse: () => ActivityEventType.orderCreated,
      );
      counts[eventType] = row['count'] as int;
    }
    
    return counts;
  }

  // Export logs to CSV format
  Future<String> exportToCsv({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final logs = await getLogs(
      fromDate: fromDate,
      toDate: toDate,
      limit: 10000,
    );

    final buffer = StringBuffer();
    buffer.writeln('ID,Event Type,Entity Type,Entity ID,Description,Created At');
    
    for (final log in logs) {
      buffer.writeln(
        '"${log.id}","${log.eventType.name}","${log.entityType.name}","${log.entityId ?? ''}","${log.description.replaceAll('"', '""')}","${log.createdAt.toIso8601String()}"'
      );
    }
    
    return buffer.toString();
  }

  // Helper: Map database row to ActivityLog
  ActivityLog _mapToActivityLog(Map<String, dynamic> map) {
    Map<String, dynamic>? metadata;
    if (map['metadata'] != null) {
      metadata = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
    }

    return ActivityLog(
      id: map['id'] as String,
      eventType: ActivityEventType.values.firstWhere(
        (e) => e.name == map['event_type'],
        orElse: () => ActivityEventType.orderCreated,
      ),
      entityType: ActivityEntityType.values.firstWhere(
        (e) => e.name == map['entity_type'],
        orElse: () => ActivityEntityType.system,
      ),
      entityId: map['entity_id'] as String?,
      description: map['description'] as String,
      metadata: metadata,
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}
