import 'package:flutter/material.dart';

/// Order Detail Screen - Placeholder
/// Shows order items and status
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Center(
        child: Text('Order Detail for ID: $orderId - Coming Soon'),
      ),
    );
  }
}
