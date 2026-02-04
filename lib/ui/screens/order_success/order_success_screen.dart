import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/color_palette.dart';
import '../../../services/cart_service.dart';
import '../../../services/order_service.dart';
import '../../../services/payment_service.dart';
import '../../../models/payment.dart';
import '../../widgets/receipt_card.dart';

/// Order Success Screen - Shows after successful order completion
class OrderSuccessScreen extends ConsumerWidget {
  final String orderId;
  final double totalAmount;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Success Icon with animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CarmenColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: CarmenColors.primaryGreen,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Success Title
              const Text(
                'Order Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Order ID
              Text(
                'Order #${orderId.substring(0, 8).toUpperCase()}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Total Amount Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: CarmenColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 3),
              
              // View Receipt Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReceiptModal(context, ref),
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  label: const Text(
                    'View Receipt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CarmenColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Back to POS Button - New Order
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Clear cart and go back to POS (index 0 of dashboard)
                    ref.read(cartProvider.notifier).clear();
                    context.go('/dashboard');
                  },
                  icon: Icon(Icons.add_shopping_cart, color: CarmenColors.primaryGreen),
                  label: Text(
                    'New Order',
                    style: TextStyle(
                      color: CarmenColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: CarmenColors.primaryGreen, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptModal(BuildContext context, WidgetRef ref) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch order and payment data
      final order = await ref.read(orderServiceProvider).getOrderById(orderId);
      final payment = await ref.read(paymentServiceProvider).getPaymentByOrderId(orderId);
      
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      if (order == null || payment == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load receipt data')),
          );
        }
        return;
      }

      // Show receipt modal
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReceiptCard(
                    order: order,
                    paymentMethod: payment.paymentMethod,
                    amountPaid: payment.amountTendered,
                    change: payment.changeAmount,
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    onPressed: () => Navigator.pop(ctx),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.pop(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading receipt: $e')),
        );
      }
    }
  }
}
