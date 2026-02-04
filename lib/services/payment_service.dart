import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/datasources/local/payment_dao.dart';
import '../models/payment.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/sync_service.dart';

/// Payment service for processing cash payments
class PaymentService {
  final PaymentDao _paymentDao = PaymentDao();
  final OrderService _orderService = OrderService();
  final SyncService? _syncService;
  final _uuid = const Uuid();

  PaymentService({SyncService? syncService}) : _syncService = syncService;

  /// Process payment
  Future<Payment> processPayment({
    required Order order,
    required double amountTendered,
    required PaymentMethod paymentMethod,
  }) async {
    if (paymentMethod == PaymentMethod.cash && amountTendered < order.totalAmount) {
      throw Exception(
        'Amount tendered (₱${amountTendered.toStringAsFixed(2)}) is less than total (₱${order.totalAmount.toStringAsFixed(2)})',
      );
    }

    // For GCash, amount tendered usually equals total
    final actualAmountTendered = paymentMethod == PaymentMethod.gcash ? order.totalAmount : amountTendered;
    final changeAmount = actualAmountTendered - order.totalAmount;
    final now = DateTime.now();

    // Create payment record
    final payment = Payment(
      id: _uuid.v4(),
      orderId: order.id,
      paymentMethod: paymentMethod,
      amountTendered: actualAmountTendered,
      changeAmount: changeAmount,
      totalAmount: order.totalAmount,
      createdAt: now,
    );

    // Save payment to database
    await _paymentDao.createPayment(payment);

    // Update order status to completed
    await _orderService.completeOrder(order.id);

    // Trigger background sync
    _syncService?.syncAll();

    return payment;
  }

  /// Get payment by order ID
  Future<Payment?> getPaymentByOrderId(String orderId) async {
    return _paymentDao.getPaymentByOrderId(orderId);
  }

  /// Get today's total cash collected
  Future<double> getTodaysTotalCash() async {
    return _paymentDao.getTodaysTotalCash();
  }

  /// Get total sales for date range
  Future<double> getTotalSales({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    return _paymentDao.getTotalSales(fromDate: fromDate, toDate: toDate);
  }

  /// Get payments for date range
  Future<List<Payment>> getPayments({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    return _paymentDao.getPayments(
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
    );
  }

  /// Get unsynced payments
  Future<List<Payment>> getUnsyncedPayments() async {
    return _paymentDao.getUnsyncedPayments();
  }

  /// Mark payment as synced
  Future<void> markAsSynced(String paymentId) async {
    await _paymentDao.markAsSynced(paymentId);
  }
}

/// Payment state for checkout flow
class PaymentState {
  final Order? currentOrder;
  final double amountTendered;
  final PaymentMethod paymentMethod;
  final Payment? completedPayment;
  final bool isProcessing;
  final String? error;

  const PaymentState({
    this.currentOrder,
    this.amountTendered = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.completedPayment,
    this.isProcessing = false,
    this.error,
  });

  /// Calculate change amount
  double get changeAmount {
    if (currentOrder == null) return 0.0;
    final change = amountTendered - currentOrder!.totalAmount;
    return change > 0 ? change : 0.0;
  }

  /// Check if payment is valid
  bool get isValidPayment {
    if (currentOrder == null) return false;
    if (paymentMethod == PaymentMethod.gcash) return true; // GCash is always valid if selected (verified by staff)
    return amountTendered >= currentOrder!.totalAmount;
  }

  PaymentState copyWith({
    Order? currentOrder,
    double? amountTendered,
    PaymentMethod? paymentMethod,
    Payment? completedPayment,
    bool? isProcessing,
    String? error,
  }) {
    return PaymentState(
      currentOrder: currentOrder ?? this.currentOrder,
      amountTendered: amountTendered ?? this.amountTendered,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      completedPayment: completedPayment ?? this.completedPayment,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

/// Payment notifier for checkout flow
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _paymentService;

  PaymentNotifier(this._paymentService) : super(const PaymentState());

  /// Set the order to pay for
  void setOrder(Order order) {
    state = PaymentState(currentOrder: order);
  }

  /// Set amount tendered
  void setAmountTendered(double amount) {
    state = state.copyWith(amountTendered: amount, error: null);
  }

  /// Add to amount tendered (for numpad)
  void addToAmount(double amount) {
    state = state.copyWith(
      amountTendered: state.amountTendered + amount,
      error: null,
    );
  }

  /// Set payment method
  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method, error: null);
  }

  /// Clear amount tendered
  void clearAmount() {
    state = state.copyWith(amountTendered: 0.0, error: null);
  }

  /// Process payment
  Future<Payment?> processPayment() async {
    if (state.currentOrder == null) {
      state = state.copyWith(error: 'No order selected');
      return null;
    }

    if (!state.isValidPayment) {
      state = state.copyWith(error: 'Insufficient amount');
      return null;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final payment = await _paymentService.processPayment(
        order: state.currentOrder!,
        amountTendered: state.amountTendered,
        paymentMethod: state.paymentMethod,
      );
      state = state.copyWith(
        completedPayment: payment,
        isProcessing: false,
      );
      return payment;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  /// Reset payment state
  void reset() {
    state = const PaymentState();
  }
}

/// Providers
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return PaymentService(syncService: syncService);
});

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return PaymentNotifier(paymentService);
});
