import 'package:flutter/material.dart';

/// Item Detail Screen - Placeholder
/// Shows item modifiers (size, milk, sugar, etc.)
class ItemDetailScreen extends StatelessWidget {
  final String itemId;
  
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: Center(
        child: Text('Item Detail for ID: $itemId - Coming Soon'),
      ),
    );
  }
}
