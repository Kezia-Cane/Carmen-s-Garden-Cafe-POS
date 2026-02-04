import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/color_palette.dart';

/// Payment Success Screen
/// Shows confirmation after successful payment
class PaymentSuccessScreen extends StatelessWidget {
  final String orderNumber;
  final double totalAmount;
  final double changeAmount;
  
  const PaymentSuccessScreen({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.changeAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CarmenColors.lightCream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: CarmenColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Success Message
                const Text(
                  'Payment Complete!',
                  style: TextStyle(
                    fontFamily: 'Epilogue',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Order Number
                Text(
                  'Order $orderNumber',
                  style: const TextStyle(
                    fontFamily: 'Epilogue',
                    fontSize: 18,
                    color: CarmenColors.olive,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Amount Details
                _buildAmountRow('Total', totalAmount),
                const SizedBox(height: 8),
                _buildAmountRow('Change', changeAmount, isHighlight: true),
                
                const SizedBox(height: 48),
                
                // New Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('New Order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAmountRow(String label, double amount, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Epilogue',
            fontSize: 18,
            color: isHighlight ? CarmenColors.primaryGreen : CarmenColors.darkBrown,
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'Epilogue',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isHighlight ? CarmenColors.primaryGreen : CarmenColors.darkBrown,
          ),
        ),
      ],
    );
  }
}
