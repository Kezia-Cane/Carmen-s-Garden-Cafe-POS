import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/color_palette.dart';
import '../../models/order.dart';
import '../../models/payment.dart';

class ReceiptCard extends StatelessWidget {
  final Order order;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;

  const ReceiptCard({
    super.key,
    required this.order,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CarmenColors.lightCream,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, color: CarmenColors.primaryGreen, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            "Carmen's Garden Cafe",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Order #', style: TextStyle(color: Colors.grey)),
              Text('${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1, height: 32),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "${item.quantity} x ₱${item.unitPrice.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  "₱${item.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )),
          const Divider(thickness: 1, height: 32),
          _receiptRow("Subtotal", "₱${order.subtotal.toStringAsFixed(2)}"),
          _receiptRow("Tax (12%)", "₱${order.taxAmount.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _receiptRow("Total", "₱${order.totalAmount.toStringAsFixed(2)}", isBold: true),
          const Divider(thickness: 1, height: 32),
          _receiptRow("Amount Paid", "₱${amountPaid.toStringAsFixed(2)}", color: CarmenColors.primaryGreen),
          _receiptRow("Payment Method", paymentMethod == PaymentMethod.gcash ? "GCash" : "Cash", color: Colors.grey),
          _receiptRow("Change", "₱${change.toStringAsFixed(2)}", color: CarmenColors.successGreen, isBold: true),
          const SizedBox(height: 32),
          const Text(
            "Thank you for dining with us!",
            style: TextStyle(
              fontStyle: FontStyle.italic, 
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
