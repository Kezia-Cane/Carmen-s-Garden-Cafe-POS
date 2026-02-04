import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/datasources/local/order_dao.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../data/datasources/local/payment_dao.dart';
import '../data/datasources/local/inventory_dao.dart';
import '../data/datasources/local/activity_log_dao.dart';
import 'connectivity_service.dart';
import 'activity_log_service.dart';

/// Sync configuration constants
class SyncConfig {
  static const int maxRetries = 5;
  static const Duration initialBackoff = Duration(seconds: 2);
  static const Duration maxBackoff = Duration(minutes: 5);
  static const Duration syncInterval = Duration(minutes: 5);
  
  // Supabase credentials
  static const String supabaseUrl = 'https://dnhkgajasjwhmakmltai.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuaGtnYWphc2p3aG1ha21sdGFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3ODE0ODIsImV4cCI6MjA4NTM1NzQ4Mn0.5_JKH071PEFp8cf5XZB0rb7oXy-qChdCibjmE4L9Dcs';
}

/// Sync status for UI display
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync state for UI
class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final String? lastError;
  final DateTime? lastSyncTime;
  final List<String> errorDetails; // Add error details list

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastError,
    this.lastSyncTime,
    this.errorDetails = const [],
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    String? lastError,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: lastError,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// SyncService - Handles offline/online data synchronization
class SyncService {
  final OrderDao _orderDao;
  final PaymentDao _paymentDao;
  final InventoryDao _inventoryDao;
  final ActivityLogDao _activityLogDao;
  final ActivityLogService _activityLogService;
  final ConnectivityService _connectivityService;
  
  final Dio _dio;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({
    required ActivityLogService activityLogService,
    required ConnectivityService connectivityService,
    OrderDao? orderDao,
    PaymentDao? paymentDao,
    InventoryDao? inventoryDao,
    ActivityLogDao? activityLogDao,
    Dio? dio,
  })  : _activityLogService = activityLogService,
        _connectivityService = connectivityService,
        _orderDao = orderDao ?? OrderDao(),
        _paymentDao = paymentDao ?? PaymentDao(),
        _inventoryDao = inventoryDao ?? InventoryDao(),
        _activityLogDao = activityLogDao ?? ActivityLogDao(),
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: SyncConfig.supabaseUrl,
          headers: {
            'apikey': SyncConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${SyncConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// Initialize sync service - start listening for connectivity changes
  void initialize() {
    // Listen for connectivity changes
    _connectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        // Trigger sync when coming online
        syncAll();
      }
    });

    // Start periodic sync timer
    _startSyncTimer();
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(SyncConfig.syncInterval, (_) {
      if (_connectivityService.isOnline) {
        syncAll();
      }
    });
  }

  /// Sync all pending data to cloud
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    if (!_connectivityService.isOnline) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    _isSyncing = true;
    int syncedCount = 0;
    List<String> errors = [];

    try {
      // Sync orders
      final orderResult = await _syncOrders();
      syncedCount += orderResult.count;
      errors.addAll(orderResult.errors);

      // Sync payments
      final paymentResult = await _syncPayments();
      syncedCount += paymentResult.count;
      errors.addAll(paymentResult.errors);

      // Sync inventory transactions
      final inventoryResult = await _syncInventoryTransactions();
      syncedCount += inventoryResult.count;
      errors.addAll(inventoryResult.errors);

      // Sync activity logs
      final activityResult = await _syncActivityLogs();
      syncedCount += activityResult.count;
      errors.addAll(activityResult.errors);

      // Log sync result
      if (errors.isEmpty) {
        await _activityLogService.logSyncCompleted(syncedCount);
        return SyncResult(
          success: true,
          message: 'Synced $syncedCount records',
          syncedCount: syncedCount,
        );
      } else {
        await _activityLogService.logSyncFailed('Partial sync: ${errors.join(", ")}');
        return SyncResult(
          success: false,
          message: 'Partial sync completed with errors',
          syncedCount: syncedCount,
          errors: errors,
        );
      }
    } catch (e) {
      await _activityLogService.logSyncFailed('Sync failed: $e');
      return SyncResult(success: false, message: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync unsynced orders to Supabase
  /// Sync unsynced orders to Supabase
  Future<_SyncTableResult> _syncOrders() async {
    List<String> errors = [];
    int count = 0;
    try {
      final unsyncedOrders = await _orderDao.getUnsyncedOrders();

      for (final order in unsyncedOrders) {
        try {
          await _dio.post(
            '/rest/v1/orders',
            data: order.toJson(),
            options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
          );
          
          // Sync order items
          for (final item in order.items) {
            await _dio.post(
              '/rest/v1/order_items',
              data: item.toJson(),
              options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
            );
          }
          
          await _orderDao.markAsSynced(order.id);
          count++;
        } catch (e) {
          errors.add('Order ${order.orderNumber}: $e');
          continue;
        }
      }

      return _SyncTableResult(count: count, errors: errors);
    } catch (e) {
      return _SyncTableResult(count: count, errors: ['Orders Fetch Failed: $e']);
    }
  }

  /// Sync unsynced payments to Supabase
  Future<_SyncTableResult> _syncPayments() async {
    List<String> errors = [];
    int count = 0;
    try {
      final unsyncedPayments = await _paymentDao.getUnsyncedPayments();

      for (final payment in unsyncedPayments) {
        try {
          await _dio.post(
            '/rest/v1/payments',
            data: payment.toJson(),
            options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
          );
          await _paymentDao.markAsSynced(payment.id);
          count++;
        } catch (e) {
          errors.add('Payment ${payment.id}: $e');
          continue;
        }
      }

      return _SyncTableResult(count: count, errors: errors);
    } catch (e) {
      return _SyncTableResult(count: count, errors: ['Payments Fetch Failed: $e']);
    }
  }

  /// Sync inventory transaction changes to Supabase
  Future<_SyncTableResult> _syncInventoryTransactions() async {
    List<String> errors = [];
    int count = 0;
    try {
      final unsyncedTransactions = await _inventoryDao.getUnsyncedTransactions();

      for (final transaction in unsyncedTransactions) {
        try {
          await _dio.post(
            '/rest/v1/inventory_transactions',
            data: transaction.toJson(),
            options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
          );
          await _inventoryDao.markTransactionAsSynced(transaction.id);
          count++;
        } catch (e) {
          errors.add('InvTx ${transaction.id}: $e');
          continue;
        }
      }

      return _SyncTableResult(count: count, errors: errors);
    } catch (e) {
      return _SyncTableResult(count: count, errors: ['Inventory Fetch Failed: $e']);
    }
  }

  /// Sync activity logs to Supabase
  Future<_SyncTableResult> _syncActivityLogs() async {
    List<String> errors = [];
    int count = 0;
    try {
      final unsyncedLogs = await _activityLogDao.getUnsyncedLogs();
      List<String> syncedIds = [];

      for (final log in unsyncedLogs) {
        try {
          await _dio.post(
            '/rest/v1/activity_logs',
            data: {
              'id': log.id,
              'event_type': log.eventType.name,
              'entity_type': log.entityType.name,
              'entity_id': log.entityId,
              'description': log.description,
              'metadata': log.metadata,
              'created_at': log.createdAt.toIso8601String(),
            },
            options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
          );
          syncedIds.add(log.id);
          count++;
        } catch (e) {
          errors.add('Log ${log.id}: $e');
          continue;
        }
      }

      if (syncedIds.isNotEmpty) {
        await _activityLogDao.markAsSynced(syncedIds);
      }

      return _SyncTableResult(count: count, errors: errors);
    } catch (e) {
      return _SyncTableResult(count: count, errors: ['Activity Logs Fetch Failed: $e']);
    }
  }

  /// Sync a single menu item to cloud (upsert)
  Future<bool> syncMenuItem(Map<String, dynamic> item) async {
    if (!_connectivityService.isOnline) return false;
    
    try {
      await _dio.post(
        '/rest/v1/menu_items',
        data: item,
        options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sync a single category to cloud (upsert)
  Future<bool> syncCategory(Map<String, dynamic> category) async {
    if (!_connectivityService.isOnline) return false;
    
    try {
      await _dio.post(
        '/rest/v1/categories',
        data: category,
        options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a menu item from cloud
  Future<bool> deleteMenuItemFromCloud(String id) async {
    if (!_connectivityService.isOnline) return false;
    
    try {
      await _dio.delete('/rest/v1/menu_items?id=eq.$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pull menu data from cloud (for menu updates)
  Future<void> pullMenuFromCloud() async {
    if (!_connectivityService.isOnline) return;

    try {
      // This would fetch categories, items, and modifiers from Supabase
      // and update local database using MenuDao.replaceAllMenuData()
      
      // Log success with placeholder counts (would be actual counts from fetched data)
      await _activityLogService.logMenuSynced(0, 0);
    } catch (e) {
      await _activityLogService.logSyncFailed('Menu sync failed: $e');
    }
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    int count = 0;
    count += (await _orderDao.getUnsyncedOrders()).length;
    count += (await _paymentDao.getUnsyncedPayments()).length;
    count += (await _inventoryDao.getUnsyncedTransactions()).length;
    return count;
  }

  /// Pull all orders from cloud (Restore)
  Future<SyncResult> pullOrdersFromCloud() async {
    if (!_connectivityService.isOnline) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    try {
      int count = 0;
      // Fetch orders with items using nested select
      // Ordering by created_at desc to get latest first, but we want all.
      // Limit to 1000 for safety, or paginate. For now, reasonable limit.
      final response = await _dio.get(
        '/rest/v1/orders',
        queryParameters: {
          'select': '*, order_items(*)',
          'order': 'created_at.desc',
          'limit': '1000', 
        },
      );

      final List<dynamic> data = response.data;

      for (final map in data) {
        try {
          // Extract items
          final itemsList = (map['order_items'] as List?) ?? [];
          final items = itemsList
              .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
              .toList();
          
          // Create order object (ignoring 'order_items' key in map)
          final order = Order.fromJson(map).copyWith(
            items: items,
            isSynced: true,
          );

          await _orderDao.restoreOrder(order);
          count++;
        } catch (e) {
          print('Error restoring order ${map['id']}: $e');
        }
      }

      return SyncResult(
        success: true, 
        message: 'Restored $count orders',
        syncedCount: count,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Restore failed: $e');
    }
  }

  /// Pull all payments from cloud
  Future<SyncResult> pullPaymentsFromCloud() async {
    if (!_connectivityService.isOnline) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    try {
      int count = 0;
      final response = await _dio.get(
        '/rest/v1/payments',
        queryParameters: {
          'order': 'created_at.desc',
          'limit': '1000',
        },
      );

      final List<dynamic> data = response.data;

      for (final map in data) {
        try {
          final payment = Payment.fromJson(map).copyWith(isSynced: true);
          await _paymentDao.restorePayment(payment);
          count++;
        } catch (e) {
          print('Error restoring payment ${map['id']}: $e');
        }
      }

      return SyncResult(
        success: true,
        message: 'Restored $count payments',
        syncedCount: count,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Payment restore failed: $e');
    }
  }

  /// Dispose resources

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _dio.close();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.errors = const [],
  });
}

class _SyncTableResult {
  final int count;
  final List<String> errors;

  _SyncTableResult({required this.count, this.errors = const []});
}

/// SyncNotifier for UI state management
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(const SyncState());

  /// Trigger manual sync
  Future<void> sync() async {
    state = state.copyWith(status: SyncStatus.syncing);
    
    final result = await _syncService.syncAll();
    final pendingCount = await _syncService.getPendingSyncCount();
    
    state = state.copyWith(
      status: result.success ? SyncStatus.success : SyncStatus.error,
      pendingCount: pendingCount,
      lastError: result.success ? null : result.message,
      lastSyncTime: DateTime.now(),
    );

    // Reset to idle after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });
  }

  /// Trigger data restore (Pull)
  Future<void> restore() async {
    state = state.copyWith(status: SyncStatus.syncing);
    
    // Pull orders
    final orderResult = await _syncService.pullOrdersFromCloud();
    
    // Pull payments
    final paymentResult = await _syncService.pullPaymentsFromCloud();
    
    final pendingCount = await _syncService.getPendingSyncCount();
    
    final success = orderResult.success && paymentResult.success;
    String? message;
    
    if (success) {
      message = 'Restored: ${orderResult.syncedCount} orders, ${paymentResult.syncedCount} payments';
    } else {
      if (!orderResult.success) message = orderResult.message;
      else message = paymentResult.message;
    }
    
    state = state.copyWith(
      status: success ? SyncStatus.success : SyncStatus.error,
      pendingCount: pendingCount,
      lastError: success ? null : message,
      lastSyncTime: DateTime.now(),
    );

    // Reset to idle after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });
  }

  /// Trigger both Sync (Push) AND Restore (Pull)
  Future<void> syncAndRestore() async {
    state = state.copyWith(status: SyncStatus.syncing);
    
    // 1. Push local changes
    final pushResult = await _syncService.syncAll();
    
    // 2. Pull remote changes (Orders)
    final pullResult = await _syncService.pullOrdersFromCloud();

    // 3. Pull payments
    final paymentPullResult = await _syncService.pullPaymentsFromCloud();
    
    final pendingCount = await _syncService.getPendingSyncCount();
    
    final success = pushResult.success && pullResult.success && paymentPullResult.success;
    String message;
    
    if (success) {
      message = 'Synced: ${pushResult.syncedCount} up, ${pullResult.syncedCount} orders, ${paymentPullResult.syncedCount} payments';
    } else {
      // Prioritize error messages
      if (!pushResult.success) message = 'Push: ${pushResult.message}';
      else if (!pullResult.success) message = 'Orders Pull: ${pullResult.message}';
      else message = 'Payments Pull: ${paymentPullResult.message}';
    }

    state = state.copyWith(
      status: success ? SyncStatus.success : SyncStatus.error,
      pendingCount: pendingCount,
      lastError: success ? null : message,
      lastSyncTime: DateTime.now(),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });
  }

  /// Update pending count
  Future<void> refreshPendingCount() async {
    final count = await _syncService.getPendingSyncCount();
    state = state.copyWith(pendingCount: count);
  }

  @override
  bool get mounted => true; // Simplified check
}

/// Providers
final syncServiceProvider = Provider<SyncService>((ref) {
  final activityLogService = ref.watch(activityLogServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  
  final service = SyncService(
    activityLogService: activityLogService,
    connectivityService: connectivityService,
  );
  
  ref.onDispose(() => service.dispose());
  return service;
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});
