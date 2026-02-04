import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/color_palette.dart';
import '../../widgets/receipt_card.dart';
import '../../../services/cart_service.dart';
import '../../../services/order_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/activity_log_service.dart';
import '../../../models/order.dart';
import '../../../models/payment.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _customerController = TextEditingController();
  
  // Payment states
  // Payment states
  String _amountInput = '';
  PaymentMethod? _selectedPaymentMethod;
  bool _isProcessing = false;
  Order? _createdOrder;
  double _changeAmount = 0;
  
  @override
  void initState() {
    super.initState();
    // Pre-fill customer name if exists in cart
    final cartState = ref.read(cartProvider);
    if (cartState.customerName != null) {
      _customerController.text = cartState.customerName!;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    if (cartState.isEmpty && _createdOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cart is empty'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to POS'),
              ),
            ],
          ),
        ),
      );
    }

    // If order created (Payment done), show Receipt Screen
    if (_createdOrder != null) {
      return _buildReceiptScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Match design background
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        title: const Text(
          'Order Summary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: CarmenColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer & Table Section
              _buildInputSection(),
              
              const SizedBox(height: 24),
              
              // Orders List
              const Text(
                'Orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              
              ...cartState.items.asMap().entries.map((entry) => _buildOrderItemCard(entry.value, entry.key)),
              
              const SizedBox(height: 24),
              
              // Payment Summary
              _buildPaymentSummary(cartState),
              
              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _showPaymentModal(context, cartState.total),
            style: ElevatedButton.styleFrom(
              backgroundColor: CarmenColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        // Customer Name Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _customerController,
            decoration: InputDecoration(
              icon: Icon(Icons.person_outline, color: CarmenColors.primaryGreen),
              hintText: 'Customer Name (Optional)',
              border: InputBorder.none,
              suffixIcon: const Icon(Icons.edit, size: 16, color: Colors.grey),
            ),
            onChanged: (val) {
              ref.read(cartProvider.notifier).setCustomerName(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemCard(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: CarmenColors.lightCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.menuItem.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(item.menuItem.imageUrl!, fit: BoxFit.cover),
                  )
                : Icon(Icons.fastfood, color: CarmenColors.olive, size: 30),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Delicious item',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${item.menuItem.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: CarmenColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).decrementQuantity(index),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(Icons.remove, size: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 4),
                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).incrementQuantity(index),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(Icons.add, size: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(CartState cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Summary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _summaryRow('Subtotal', '₱${cart.subtotal.toStringAsFixed(2)}'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grand Total',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '₱${cart.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showPaymentModal(BuildContext context, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Back Button (if method selected)
                if (_selectedPaymentMethod != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setModalState(() {
                        _selectedPaymentMethod = null;
                        _amountInput = '';
                      }),
                    ),
                  ),
                
                // Content
                Expanded(
                  child: _selectedPaymentMethod == null
                      ? _buildPaymentMethodSelection(setModalState)
                      : (_selectedPaymentMethod == PaymentMethod.cash
                          ? _buildCashKeypad(context, setModalState, total)
                          : _buildGCashPayment(context, setModalState, total)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelection(StateSetter setModalState) {
    return Column(
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _paymentMethodCard(
                  icon: Icons.payments_outlined,
                  label: 'Cash',
                  color: Colors.green,
                  onTap: () => setModalState(() => _selectedPaymentMethod = PaymentMethod.cash),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _paymentMethodCard(
                  icon: Icons.qr_code_scanner,
                  label: 'GCash',
                  color: Colors.blue,
                  onTap: () => setModalState(() => _selectedPaymentMethod = PaymentMethod.gcash),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentMethodCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGCashPayment(BuildContext context, StateSetter setModalState, double total) {
    return Column(
      children: [
        const Text(
          'Scan to Pay with GCash',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Text(
          'Total: ₱${total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Virtual QR Code
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.file(
            // Use the actual path from the image generation
            File('C:/Users/Administrator/.gemini/antigravity/brain/19ea5f65-11a1-40be-bc7f-5fa5310e27a1/gcash_qr_code_placeholder_1769711283959.png'),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.qr_code, size: 100, color: Colors.blue),
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setModalState(() => _isProcessing = true);
                      Navigator.pop(context);
                      await _processPayment(total, 0, method: PaymentMethod.gcash);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Receive Payment',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashKeypad(BuildContext context, StateSetter setModalState, double total) {
    final amountEntered = double.tryParse(_amountInput) ?? 0.0;
    final canPay = amountEntered >= (total - 0.01);
    final change = canPay ? amountEntered - total : 0.0;

    return Column(
      children: [
        const Text(
          'Enter Cash Amount',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _amountInput.isEmpty ? '₱0' : '₱$_amountInput',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: CarmenColors.primaryGreen,
          ),
        ),
        // Reserve space for Change text to prevent layout shift
        SizedBox(
          height: 24,
          child: Visibility(
            visible: canPay,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              'Change: ₱${change.toStringAsFixed(2)}',
              style: TextStyle(
                color: CarmenColors.successGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Numpad
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.2, // Increased to make buttons shorter
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => TextButton(
                    onPressed: () => setModalState(() {
                      if (_amountInput.length < 6) _amountInput += n.toString();
                    }),
                    child: Text('$n',
                        style: const TextStyle(
                            fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold)),
                  )),
              TextButton(
                onPressed: () => setModalState(() => _amountInput = ''),
                child: const Text('C',
                    style:
                        TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setModalState(() {
                  if (_amountInput.length < 6) _amountInput += '0';
                }),
                child: const Text('0',
                    style: const TextStyle(
                        fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setModalState(() {
                  if (_amountInput.isNotEmpty) {
                    _amountInput = _amountInput.substring(0, _amountInput.length - 1);
                  }
                }),
                child: const Icon(Icons.backspace_outlined, color: Colors.black, size: 28),
              ),
            ],
          ),
        ),
        // Pay Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canPay && !_isProcessing
                  ? () async {
                      setModalState(() => _isProcessing = true);
                      Navigator.pop(context);
                      await _processPayment(total, change, method: PaymentMethod.cash);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: CarmenColors.successGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Complete Payment',
                      style:
                          TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment(double total, double change, {required PaymentMethod method}) async {
    setState(() {
      _isProcessing = true;
      _selectedPaymentMethod = method;
    });

    try {
      final cartState = ref.read(cartProvider);
      final orderService = ref.read(orderServiceProvider);
      final paymentService = ref.read(paymentServiceProvider);
      final activityLogService = ref.read(activityLogServiceProvider);
      
      // Create order
      final order = await orderService.createOrder(
        cart: cartState,
        notes: null,
      );

      _createdOrder = order;
      _changeAmount = change;

      // Process payment
      final payment = await paymentService.processPayment(
        order: order,
        amountTendered: method == PaymentMethod.cash ? double.parse(_amountInput) : total,
        paymentMethod: method,
      );

      // Log activity
      await activityLogService.logOrderCreated(order.id, order.orderNumber, order.totalAmount);
      await activityLogService.logPaymentProcessed(
        payment.id, 
        order.orderNumber, 
        payment.totalAmount, 
        payment.changeAmount,
      );

      // Navigate to Order Success Screen
      if (mounted) {
        // Clear cart
        ref.read(cartProvider.notifier).clear();
        // Navigate to success screen with order info
        context.go('/order-success/${order.id}/${order.totalAmount.toStringAsFixed(2)}');
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildReceiptScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Receipt', style: TextStyle(color: Colors.white)),
        backgroundColor: CarmenColors.primaryGreen,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildReceiptCard(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).clear();
                    context.go('/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CarmenColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text(
                    'Start New Order',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  // Placeholder for print functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Printing receipt...')),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Print Receipt'),
                style: TextButton.styleFrom(foregroundColor: CarmenColors.primaryGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    final order = _createdOrder!;
    
    return ReceiptCard(
      order: order, 
      paymentMethod: _selectedPaymentMethod ?? PaymentMethod.cash, 
      amountPaid: _selectedPaymentMethod == PaymentMethod.cash ? double.parse(_amountInput) : order.totalAmount, 
      change: _changeAmount,
    );
  }

}
