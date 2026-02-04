import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/color_palette.dart';
import '../../../services/menu_service.dart';
import '../../../services/cart_service.dart';
import '../../../models/menu_item.dart';

/// POS Screen with Variant Selection
class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuProvider.notifier).loadMenu();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Point of Sale',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: CarmenColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar - Same style as Inventory
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search items...',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close, color: Colors.grey, size: 20),
                        ),
                    ],
                  ),
                ),
              ),

              // Category Tabs
              if (menuState.categories.isNotEmpty)
                _buildCategoryList(menuState),

              // Menu Grid
              Expanded(
                child: _buildMenuGrid(menuState, cartState),
              ),
            ],
          ),

          // Floating Checkout Button
          if (cartState.items.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildFloatingCheckoutButton(cartState),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(MenuState menuState) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: menuState.categories.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = menuState.categories[index];
          final isSelected = category.id == menuState.selectedCategoryId;
          
          return GestureDetector(
            onTap: () {
              ref.read(menuProvider.notifier).selectCategory(category.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? CarmenColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid(MenuState menuState, CartState cartState) {
    if (menuState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var availableItems = menuState.filteredItems.where((i) => i.isAvailable).toList();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      availableItems = availableItems.where((i) => i.name.toLowerCase().contains(_searchQuery)).toList();
    }

    if (availableItems.isEmpty) {
      return const Center(child: Text("No items found"));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Increased height to prevent overflow
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: availableItems.length,
      itemBuilder: (context, index) {
        final item = availableItems[index];
        return _buildItemCard(item, menuState);
      },
    );
  }

  Widget _buildItemCard(MenuItem item, MenuState menuState) {
    // Get modifiers for this item
    final modifiers = menuState.modifiers.where((m) => m.menuItemId == item.id).toList();
    final hasVariants = modifiers.isNotEmpty;

    return GestureDetector(
      onTap: () => _showVariantModal(item, modifiers),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: CarmenColors.lightCream,
                child: _buildItemImage(item),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (hasVariants)
                      Text(
                        'Tap to select variant',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (item.description != null && item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    // Add button - Clean circular design
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: CarmenColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVariantModal(MenuItem item, List<ItemModifier> modifiers) {
    if (modifiers.isEmpty) {
      // No variants, add directly
      ref.read(cartProvider.notifier).addItem(item);
      _showAddedSnackbar(item.name, item.price);
      return;
    }

    // Show variant selection modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VariantSelectionModal(
        item: item,
        modifiers: modifiers,
        onAdd: (selectedModifiers, totalPrice) {
          ref.read(cartProvider.notifier).addItemWithModifiers(
            item,
            selectedModifiers,
            totalPrice,
          );
          Navigator.pop(context);
          _showAddedSnackbar(item.name, totalPrice);
        },
      ),
    );
  }

  void _showAddedSnackbar(String itemName, double price) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemName - ₱${price.toStringAsFixed(0)}'),
        duration: const Duration(seconds: 1),
        backgroundColor: CarmenColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFloatingCheckoutButton(CartState cart) {
    return InkWell(
      key: const Key('checkout_btn'),
      onTap: () => context.go('/checkout'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: CarmenColors.primaryGreen,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: CarmenColors.primaryGreen.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text(
              'Proceed Order',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '${cart.totalItems} Items',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₱${cart.total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(MenuItem item) {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return Icon(Icons.fastfood, size: 40, color: CarmenColors.olive);
    }
    
    if (item.imageUrl!.startsWith('http')) {
      return Image.network(
        item.imageUrl!, 
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Colors.grey[400]),
      );
    } else {
      return Image.file(
        File(item.imageUrl!), 
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Colors.grey[400]),
      );
    }
  }
}

/// Variant Selection Modal
class _VariantSelectionModal extends StatefulWidget {
  final MenuItem item;
  final List<ItemModifier> modifiers;
  final Function(List<String>, double) onAdd;

  const _VariantSelectionModal({
    required this.item,
    required this.modifiers,
    required this.onAdd,
  });

  @override
  State<_VariantSelectionModal> createState() => _VariantSelectionModalState();
}

class _VariantSelectionModalState extends State<_VariantSelectionModal> {
  final Map<String, int> _selectedOptions = {};
  
  @override
  void initState() {
    super.initState();
    // Default select first option for each modifier
    for (final modifier in widget.modifiers) {
      if (modifier.options.isNotEmpty) {
        _selectedOptions[modifier.id] = 0;
      }
    }
  }

  double get _totalPrice {
    double total = widget.item.price;
    for (final modifier in widget.modifiers) {
      final selectedIndex = _selectedOptions[modifier.id] ?? 0;
      if (selectedIndex < modifier.options.length) {
        total += modifier.options[selectedIndex].priceAdjustment;
      }
    }
    return total;
  }

  List<String> get _selectedModifierNames {
    List<String> names = [];
    for (final modifier in widget.modifiers) {
      final selectedIndex = _selectedOptions[modifier.id] ?? 0;
      if (selectedIndex < modifier.options.length) {
        names.add(modifier.options[selectedIndex].name);
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Variant Options
          for (final modifier in widget.modifiers) ...[
            Text(
              'Select ${modifier.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(modifier.options.length, (index) {
                final option = modifier.options[index];
                final isSelected = _selectedOptions[modifier.id] == index;
                final displayPrice = widget.item.price + option.priceAdjustment;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOptions[modifier.id] = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? CarmenColors.primaryGreen : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected 
                          ? Border.all(color: CarmenColors.primaryGreen, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          option.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₱${displayPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // Total and Add Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₱${_totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CarmenColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    widget.onAdd(_selectedModifierNames, _totalPrice);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CarmenColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
