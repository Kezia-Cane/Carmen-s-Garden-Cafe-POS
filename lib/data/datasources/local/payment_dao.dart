import 'package:sqflite/sqflite.dart';
import '../../database_helper.dart';
import '../../../models/payment.dart';

/// Payment Data Access Object
/// Handles all payment-related database operations
class PaymentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create payment record
  Future<Payment> createPayment(Payment payment) async {
    final db = await _dbHelper.database;
    await db.insert('payments', {
      'id': payment.id,
      'order_id': payment.orderId,
      'payment_method': payment.paymentMethod.name,
      'amount_tendered': payment.amountTendered,
      'change_amount': payment.changeAmount,
      'total_amount': payment.totalAmount,
      'created_at': payment.createdAt.toIso8601String(),
      'is_synced': payment.isSynced ? 1 : 0,
    });
    return payment;
  }

  // Restore payment from cloud (upsert)
  Future<void> restorePayment(Payment payment) async {
    final db = await _dbHelper.database;
    await db.insert('payments', {
      'id': payment.id,
      'order_id': payment.orderId,
      'payment_method': payment.paymentMethod.name,
      'amount_tendered': payment.amountTendered,
      'change_amount': payment.changeAmount,
      'total_amount': payment.totalAmount,
      'created_at': payment.createdAt.toIso8601String(),
      'is_synced': 1, // Restored payments are already synced
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get payment by order ID
  Future<Payment?> getPaymentByOrderId(String orderId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    if (maps.isEmpty) return null;
    return _mapToPayment(maps.first);
  }

  // Get all payments for a date range
  Future<List<Payment>> getPayments({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
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

    final maps = await db.query(
      'payments',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map(_mapToPayment).toList();
  }

  // Get today's total cash collected
  Future<double> getTodaysTotalCash() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM payments WHERE created_at >= ?',
      [startOfDay.toIso8601String()],
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total sales for a date range
  Future<double> getTotalSales({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM payments WHERE created_at >= ? AND created_at <= ?',
      [fromDate.toIso8601String(), toDate.toIso8601String()],
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get unsynced payments
  Future<List<Payment>> getUnsyncedPayments() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );
    return maps.map(_mapToPayment).toList();
  }

  // Mark payment as synced
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'payments',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper: Map database row to Payment
  Payment _mapToPayment(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      paymentMethod: PaymentMethod.values.firstWhere(
        (m) => m.name == map['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      amountTendered: (map['amount_tendered'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}
