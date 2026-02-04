import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../data/datasources/local/order_dao.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import '../services/activity_log_service.dart';
import '../services/sync_service.dart';

/// Order service for creating and managing orders
class OrderService {
  final OrderDao _orderDao;
  final DatabaseHelper _dbHelper;
  final Uuid _uuid;

  final SyncService? _syncService; // Optional to avoid direct hard dependency if possible, but simpler to just pass it.
  final ActivityLogService? _activityLogService;

  OrderService({
    OrderDao? orderDao,
    DatabaseHelper? dbHelper,
    Uuid? uuid,
    SyncService? syncService,
    ActivityLogService? activityLogService,
  })  : _orderDao = orderDao ?? OrderDao(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _uuid = uuid ?? const Uuid(),
        _syncService = syncService,
        _activityLogService = activityLogService;

  /// Create a new order from the current cart
  Future<Order> createOrder({
    required CartState cart,
    String? notes,
  }) async {
    if (cart.isEmpty) {
      throw Exception('Cannot create order with empty cart');
    }

    // Get next order number
    final orderNumber = await _dbHelper.getNextOrderNumber();
    final orderId = _uuid.v4();
    final now = DateTime.now();

    // Create order items from cart
    final orderItems = cart.items.map((cartItem) => OrderItem(
      id: _uuid.v4(),
      orderId: orderId,
      menuItemId: cartItem.menuItem.id,
      name: cartItem.menuItem.name,
      unitPrice: cartItem.menuItem.price,
      totalPrice: cartItem.totalPrice,
      quantity: cartItem.quantity,
      modifiers: [],
      createdAt: now,
    )).toList();

    // Create order
    final order = Order(
      id: orderId,
      orderNumber: orderNumber,
      customerName: cart.customerName,
      status: OrderStatus.pending,
      subtotal: cart.subtotal,
      taxAmount: cart.taxAmount,
      totalAmount: cart.total,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      items: orderItems,
    );

    // Save to database
    await _orderDao.createOrder(order);

    // NOTE: Cart is NOT cleared here - caller should clear after showing receipt

    // Trigger background sync
    _syncService?.syncAll();

    return order;
  }

  /// Get order by ID
  Future<Order?> getOrderById(String id) async {
    return _orderDao.getOrderById(id);
  }

  /// Get all orders with optional filters
  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return _orderDao.getOrders(
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
      offset: offset,
    );
  }

  /// Get today's orders
  Future<List<Order>> getTodaysOrders() async {
    return _orderDao.getTodaysOrders();
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orderDao.updateOrderStatus(orderId, status);
    
    // Log activity
    final order = await getOrderById(orderId);
    if (order != null) {
      if (status == OrderStatus.completed) {
        _activityLogService?.logOrderCompleted(orderId, order.orderNumber, order.totalAmount);
      } else if (status == OrderStatus.cancelled) {
        _activityLogService?.logOrderCancelled(orderId, order.orderNumber);
      } else if (status == OrderStatus.voided) {
        _activityLogService?.logOrderVoided(orderId, order.orderNumber);
      }
    }

    // Trigger background sync
    _syncService?.syncAll();
  }

  /// Get order count by status (for dashboard)
  Future<Map<OrderStatus, int>> getOrderCountByStatus() async {
    return _orderDao.getOrderCountByStatus();
  }

  /// Mark order as preparing
  Future<void> startPreparing(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.preparing);
  }

  /// Mark order as ready
  Future<void> markReady(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.ready);
  }

  /// Complete order
  Future<void> completeOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.completed);
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  /// Void order (requires password verification at UI level)
  Future<void> voidOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.voided);
  }

  /// Get unsynced orders for cloud sync
  Future<List<Order>> getUnsyncedOrders() async {
    return _orderDao.getUnsyncedOrders();
  }

  /// Mark order as synced
  Future<void> markAsSynced(String orderId) async {
    await _orderDao.markAsSynced(orderId);
  }
}

/// Orders state for UI
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final OrderStatus? filterStatus;
  final DateTime? fromDate;
  final DateTime? toDate;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
    this.fromDate,
    this.toDate,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    OrderStatus? filterStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStatus: filterStatus ?? this.filterStatus,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

/// Orders notifier for UI state management
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;

  OrdersNotifier(this._orderService) : super(const OrdersState());

  /// Load today's orders
  Future<void> loadTodaysOrders() async {
    state = state.copyWith(isLoading: true, error: null, filterStatus: null, fromDate: null, toDate: null);
    try {
      final orders = await _orderService.getTodaysOrders();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load orders with filter
  Future<void> loadOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) async {
    state = state.copyWith(
      isLoading: true, 
      error: null, 
      filterStatus: status,
      fromDate: fromDate,
      toDate: toDate,
    );
    try {
      final orders = await _orderService.getOrders(
        status: status,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      );
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update order status and refresh list
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _orderService.updateOrderStatus(orderId, status);
    await loadTodaysOrders();
  }

  /// Refresh orders
  Future<void> refresh() async {
    if (state.filterStatus != null) {
      await loadOrders(status: state.filterStatus);
    } else {
      await loadTodaysOrders();
    }
  }
}

/// Providers
final orderServiceProvider = Provider<OrderService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final activityLogService = ref.watch(activityLogServiceProvider);
  return OrderService(
    syncService: syncService,
    activityLogService: activityLogService,
  );
});

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return OrdersNotifier(orderService);
});
