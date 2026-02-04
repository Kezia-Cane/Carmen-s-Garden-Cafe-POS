import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../database_helper.dart';
import '../../../models/order.dart';

/// Order Data Access Object
/// Handles all order-related database operations
class OrderDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create a new order
  Future<Order> createOrder(Order order) async {
    final db = await _dbHelper.database;
    
    // Insert order
    await db.insert('orders', {
      'id': order.id,
      'order_number': order.orderNumber,
      'customer_name': order.customerName,
      'status': order.status.name,
      'subtotal': order.subtotal,
      'tax_amount': order.taxAmount,
      'total_amount': order.totalAmount,
      'notes': order.notes,
      'created_at': order.createdAt.toIso8601String(),
      'updated_at': order.updatedAt.toIso8601String(),
      'completed_at': order.completedAt?.toIso8601String(),
      'is_synced': order.isSynced ? 1 : 0,
    });

    // Insert order items
    for (final item in order.items) {
      await db.insert('order_items', {
        'id': item.id,
        'order_id': order.id,
        'menu_item_id': item.menuItemId,
        'name': item.name,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.totalPrice,
        'modifiers': jsonEncode(item.modifiers.map((m) => m.toJson()).toList()),
        'special_instructions': item.specialInstructions,
        'created_at': item.createdAt.toIso8601String(),
      });
    }

    return order;
  }

  // Restore/Upsert an order from cloud
  Future<void> restoreOrder(Order order) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // 1. Delete existing items to prevent duplicates/orphans
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      // 2. Insert or Replace the order
      await txn.insert(
        'orders', 
        {
          'id': order.id,
          'order_number': order.orderNumber,
          'customer_name': order.customerName,
          'status': order.status.name,
          'subtotal': order.subtotal,
          'tax_amount': order.taxAmount,
          'total_amount': order.totalAmount,
          'notes': order.notes,
          'created_at': order.createdAt.toIso8601String(),
          'updated_at': order.updatedAt.toIso8601String(),
          'completed_at': order.completedAt?.toIso8601String(),
          'is_synced': 1, // Mark as synced since it came from cloud
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Re-insert items
      for (final item in order.items) {
        await txn.insert(
          'order_items', 
          {
            'id': item.id,
            'order_id': order.id,
            'menu_item_id': item.menuItemId,
            'name': item.name,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'total_price': item.totalPrice,
            'modifiers': jsonEncode(item.modifiers.map((m) => m.toJson()).toList()),
            'special_instructions': item.specialInstructions,
            'created_at': item.createdAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get order by ID with items
  Future<Order?> getOrderById(String id) async {
    final db = await _dbHelper.database;
    
    final orderMaps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (orderMaps.isEmpty) return null;

    final orderMap = orderMaps.first;
    final items = await _getOrderItems(db, id);

    return _mapToOrder(orderMap, items);
  }

  // Get orders with optional filters
  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.name);
    }

    if (fromDate != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(toDate.toIso8601String());
    }

    final orderMaps = await db.query(
      'orders',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    List<Order> orders = [];
    for (final orderMap in orderMaps) {
      final items = await _getOrderItems(db, orderMap['id'] as String);
      orders.add(_mapToOrder(orderMap, items));
    }

    return orders;
  }

  // Get today's orders
  Future<List<Order>> getTodaysOrders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getOrders(fromDate: startOfDay, toDate: endOfDay, limit: 1000);
  }

  // Update order status
  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    
    Map<String, dynamic> updates = {
      'status': status.name,
      'updated_at': now.toIso8601String(),
      'is_synced': 0,
    };

    if (status == OrderStatus.completed || status == OrderStatus.cancelled) {
      updates['completed_at'] = now.toIso8601String();
    }

    await db.update(
      'orders',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete order (soft delete - marks as cancelled)
  Future<void> deleteOrder(String id) async {
    await updateOrderStatus(id, OrderStatus.cancelled);
  }

  // Get unsynced orders
  Future<List<Order>> getUnsyncedOrders() async {
    final db = await _dbHelper.database;
    
    final orderMaps = await db.query(
      'orders',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );

    List<Order> orders = [];
    for (final orderMap in orderMaps) {
      final items = await _getOrderItems(db, orderMap['id'] as String);
      orders.add(_mapToOrder(orderMap, items));
    }

    return orders;
  }

  // Mark order as synced
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'orders',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get order count by status
  Future<Map<OrderStatus, int>> getOrderCountByStatus() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    Map<OrderStatus, int> counts = {};
    for (final status in OrderStatus.values) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE status = ? AND created_at >= ?',
        [status.name, startOfDay.toIso8601String()],
      );
      counts[status] = (result.first['count'] as int?) ?? 0;
    }
    
    return counts;
  }

  // Helper: Get order items
  Future<List<OrderItem>> _getOrderItems(Database db, String orderId) async {
    final itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    return itemMaps.map((map) {
      List<SelectedModifier> modifiers = [];
      if (map['modifiers'] != null) {
        final modifiersList = jsonDecode(map['modifiers'] as String) as List;
        modifiers = modifiersList
            .map((m) => SelectedModifier.fromJson(m as Map<String, dynamic>))
            .toList();
      }

      return OrderItem(
        id: map['id'] as String,
        orderId: map['order_id'] as String,
        menuItemId: map['menu_item_id'] as String,
        name: map['name'] as String,
        quantity: map['quantity'] as int,
        unitPrice: (map['unit_price'] as num).toDouble(),
        totalPrice: (map['total_price'] as num).toDouble(),
        modifiers: modifiers,
        specialInstructions: map['special_instructions'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  // Helper: Map database row to Order
  Order _mapToOrder(Map<String, dynamic> map, List<OrderItem> items) {
    return Order(
      id: map['id'] as String,
      orderNumber: map['order_number'] as int,
      customerName: map['customer_name'] as String?,
      status: OrderStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at'] as String) 
          : null,
      isSynced: (map['is_synced'] as int) == 1,
      items: items,
    );
  }
}
