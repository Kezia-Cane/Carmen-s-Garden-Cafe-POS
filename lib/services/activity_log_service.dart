import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/datasources/local/activity_log_dao.dart';
import '../models/activity_log.dart';
import '../config/constants.dart';

/// Activity log service for tracking all system events
class ActivityLogService {
  final ActivityLogDao _activityLogDao = ActivityLogDao();
  final _uuid = const Uuid();

  /// Log an event
  Future<ActivityLog> logEvent({
    required ActivityEventType eventType,
    required ActivityEntityType entityType,
    String? entityId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final log = ActivityLog(
      id: _uuid.v4(),
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      description: description,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    return _activityLogDao.createLog(log);
  }

  // ============ ORDER EVENTS ============

  Future<ActivityLog> logOrderCreated(String orderId, int orderNumber, double total) async {
    return logEvent(
      eventType: ActivityEventType.orderCreated,
      entityType: ActivityEntityType.order,
      entityId: orderId,
      description: 'Order #$orderNumber created - ₱${total.toStringAsFixed(2)}',
      metadata: {'order_number': orderNumber, 'total': total},
    );
  }

  Future<ActivityLog> logOrderUpdated(String orderId, int orderNumber, String changes) async {
    return logEvent(
      eventType: ActivityEventType.orderUpdated,
      entityType: ActivityEntityType.order,
      entityId: orderId,
      description: 'Order #$orderNumber updated: $changes',
      metadata: {'order_number': orderNumber, 'changes': changes},
    );
  }

  Future<ActivityLog> logOrderStatusChanged(
    String orderId,
    int orderNumber,
    String oldStatus,
    String newStatus,
  ) async {
    return logEvent(
      eventType: ActivityEventType.orderStatusChanged,
      entityType: ActivityEntityType.order,
      entityId: orderId,
      description: 'Order #$orderNumber: $oldStatus → $newStatus',
      metadata: {'order_number': orderNumber, 'old_status': oldStatus, 'new_status': newStatus},
    );
  }

  Future<ActivityLog> logOrderCompleted(String orderId, int orderNumber, double total) async {
    return logEvent(
      eventType: ActivityEventType.orderCompleted,
      entityType: ActivityEntityType.order,
      entityId: orderId,
      description: 'Order #$orderNumber completed - ₱${total.toStringAsFixed(2)}',
      metadata: {'order_number': orderNumber, 'total': total},
    );
  }

  Future<ActivityLog> logOrderCancelled(String orderId, int orderNumber) async {
    return logEvent(
      eventType: ActivityEventType.orderCancelled,
      entityType: ActivityEntityType.order,
      entityId: orderId,
      description: 'Order #$orderNumber cancelled',
      metadata: {'order_number': orderNumber},
    );
  }

  Future<ActivityLog> logOrderVoided(String orderId, int orderNumber) async {
    return logEvent(
      eventType: ActivityEventType.orderVoided,
      entityType: ActivityEntityType.order,
      entityId: orderId,
      description: 'Order #$orderNumber voided',
      metadata: {'order_number': orderNumber},
    );
  }

  Future<ActivityLog> logOrderDeleted(String orderId, int orderNumber) async {
    return logEvent(
      eventType: ActivityEventType.orderDeleted,
      entityType: ActivityEntityType.order,
      entityId: orderId,
      description: 'Order #$orderNumber deleted',
      metadata: {'order_number': orderNumber},
    );
  }

  // ============ PAYMENT EVENTS ============

  Future<ActivityLog> logPaymentProcessed(
    String paymentId,
    int orderNumber,
    double amount,
    double change,
  ) async {
    return logEvent(
      eventType: ActivityEventType.paymentProcessed,
      entityType: ActivityEntityType.payment,
      entityId: paymentId,
      description: 'Payment for Order #$orderNumber - ₱${amount.toStringAsFixed(2)} (Change: ₱${change.toStringAsFixed(2)})',
      metadata: {'order_number': orderNumber, 'amount': amount, 'change': change},
    );
  }

  Future<ActivityLog> logPaymentRefunded(
    String paymentId,
    int orderNumber,
    double amount,
    String reason,
  ) async {
    return logEvent(
      eventType: ActivityEventType.paymentRefunded,
      entityType: ActivityEntityType.payment,
      entityId: paymentId,
      description: 'Refund for Order #$orderNumber - ₱${amount.toStringAsFixed(2)} ($reason)',
      metadata: {'order_number': orderNumber, 'amount': amount, 'reason': reason},
    );
  }

  // ============ INVENTORY EVENTS ============

  Future<ActivityLog> logInventoryAdjusted(
    String itemName,
    int adjustment,
    String reason,
    int newStock,
  ) async {
    final adjustmentStr = adjustment > 0 ? '+$adjustment' : '$adjustment';
    return logEvent(
      eventType: ActivityEventType.inventoryAdjusted,
      entityType: ActivityEntityType.inventory,
      description: '$itemName: $adjustmentStr ($reason) → $newStock in stock',
      metadata: {'item_name': itemName, 'adjustment': adjustment, 'reason': reason, 'new_stock': newStock},
    );
  }

  Future<ActivityLog> logItemAdded(String itemName, String category) async {
    return logEvent(
      eventType: ActivityEventType.itemAdded,
      entityType: ActivityEntityType.menuItem,
      description: 'New menu item added: $itemName ($category)',
      metadata: {'item_name': itemName, 'category': category},
    );
  }

  Future<ActivityLog> logItemUpdated(String itemName, String changes) async {
    return logEvent(
      eventType: ActivityEventType.itemUpdated,
      entityType: ActivityEntityType.menuItem,
      description: 'Menu item updated: $itemName',
      metadata: {'item_name': itemName, 'changes': changes},
    );
  }

  Future<ActivityLog> logItemDeleted(String itemName) async {
    return logEvent(
      eventType: ActivityEventType.itemDeleted,
      entityType: ActivityEntityType.menuItem,
      description: 'Menu item deleted: $itemName',
      metadata: {'item_name': itemName},
    );
  }

  Future<ActivityLog> logInventoryRestocked(String itemName, int quantity, int newStock) async {
    return logEvent(
      eventType: ActivityEventType.inventoryRestocked,
      entityType: ActivityEntityType.inventory,
      description: '$itemName restocked: +$quantity → $newStock in stock',
      metadata: {'item_name': itemName, 'quantity': quantity, 'new_stock': newStock},
    );
  }

  // ============ SYNC EVENTS ============

  Future<ActivityLog> logSyncCompleted(int recordCount) async {
    return logEvent(
      eventType: ActivityEventType.syncCompleted,
      entityType: ActivityEntityType.system,
      description: 'Cloud sync completed - $recordCount records synced',
      metadata: {'record_count': recordCount},
    );
  }

  Future<ActivityLog> logSyncFailed(String error) async {
    return logEvent(
      eventType: ActivityEventType.syncFailed,
      entityType: ActivityEntityType.system,
      description: 'Cloud sync failed: $error',
      metadata: {'error': error},
    );
  }

  Future<ActivityLog> logDataExported(String exportType, int recordCount) async {
    return logEvent(
      eventType: ActivityEventType.dataExported,
      entityType: ActivityEntityType.system,
      description: 'Data export generated ($exportType) - $recordCount records',
      metadata: {'export_type': exportType, 'record_count': recordCount},
    );
  }

  Future<ActivityLog> logMenuSynced(int categoryCount, int itemCount) async {
    return logEvent(
      eventType: ActivityEventType.menuSynced,
      entityType: ActivityEntityType.system,
      description: 'Menu synced - $categoryCount categories, $itemCount items',
      metadata: {'category_count': categoryCount, 'item_count': itemCount},
    );
  }

  // ============ QUERY METHODS ============

  /// Get activity logs with optional filters
  Future<List<ActivityLog>> getLogs({
    ActivityEventType? eventType,
    ActivityEntityType? entityType,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    return _activityLogDao.getLogs(
      eventType: eventType,
      entityType: entityType,
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
    );
  }

  /// Get today's logs
  Future<List<ActivityLog>> getTodaysLogs() async {
    return _activityLogDao.getTodaysLogs();
  }

  /// Get event counts by type
  Future<Map<ActivityEventType, int>> getEventCounts({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return _activityLogDao.getEventCounts(fromDate: fromDate, toDate: toDate);
  }

  /// Export logs to CSV
  Future<String> exportToCsv({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return _activityLogDao.exportToCsv(fromDate: fromDate, toDate: toDate);
  }

  /// Clean up old logs
  Future<int> cleanupOldLogs() async {
    return _activityLogDao.cleanupOldLogs(
      retentionDays: AppConstants.activityLogRetentionDays,
    );
  }

  /// Get unsynced logs
  Future<List<ActivityLog>> getUnsyncedLogs() async {
    return _activityLogDao.getUnsyncedLogs();
  }

  /// Mark logs as synced
  Future<void> markAsSynced(List<String> ids) async {
    await _activityLogDao.markAsSynced(ids);
  }
}

/// Activity log state for UI
class ActivityLogState {
  final List<ActivityLog> logs;
  final bool isLoading;
  final String? error;
  final ActivityEventType? filterEventType;
  final ActivityEntityType? filterEntityType;

  const ActivityLogState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.filterEventType,
    this.filterEntityType,
  });

  ActivityLogState copyWith({
    List<ActivityLog>? logs,
    bool? isLoading,
    String? error,
    ActivityEventType? filterEventType,
    ActivityEntityType? filterEntityType,
  }) {
    return ActivityLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterEventType: filterEventType,
      filterEntityType: filterEntityType,
    );
  }
}

/// Activity log notifier for UI
class ActivityLogNotifier extends StateNotifier<ActivityLogState> {
  final ActivityLogService _activityLogService;

  ActivityLogNotifier(this._activityLogService) : super(const ActivityLogState());

  /// Load today's logs
  Future<void> loadTodaysLogs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final logs = await _activityLogService.getTodaysLogs();
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load logs with filters
  Future<void> loadLogs({
    ActivityEventType? eventType,
    ActivityEntityType? entityType,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterEventType: eventType,
      filterEntityType: entityType,
    );
    try {
      final logs = await _activityLogService.getLogs(
        eventType: eventType,
        entityType: entityType,
      );
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh logs
  Future<void> refresh() async {
    if (state.filterEventType != null || state.filterEntityType != null) {
      await loadLogs(
        eventType: state.filterEventType,
        entityType: state.filterEntityType,
      );
    } else {
      await loadTodaysLogs();
    }
  }

  /// Clear filters
  Future<void> clearFilters() async {
    state = state.copyWith(filterEventType: null, filterEntityType: null);
    await loadTodaysLogs();
  }
}

/// Providers
final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

final activityLogProvider = StateNotifierProvider<ActivityLogNotifier, ActivityLogState>((ref) {
  final activityLogService = ref.watch(activityLogServiceProvider);
  return ActivityLogNotifier(activityLogService);
});
