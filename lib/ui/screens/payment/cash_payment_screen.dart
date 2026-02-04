import 'package:flutter/material.dart';

/// Cash Payment Screen - Placeholder
/// Handles cash input and change calculation
class CashPaymentScreen extends StatelessWidget {
  final String orderId;
  final double totalAmount;
  
  const CashPaymentScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Text('Cash Payment for ₱${totalAmount.toStringAsFixed(2)} - Coming Soon'),
      ),
    );
  }
}
