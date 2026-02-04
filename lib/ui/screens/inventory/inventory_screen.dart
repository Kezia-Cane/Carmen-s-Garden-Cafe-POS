import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../config/color_palette.dart';
import '../../../services/menu_service.dart';
import '../../../services/inventory_service.dart';
import '../../../models/menu_item.dart';
import '../../../models/category.dart';
import '../../../models/inventory.dart';
import 'item_form_modal.dart';

/// Item Management Screen - Unified Menu and Stock Management
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuProvider.notifier).loadMenu();
      ref.read(inventoryProvider.notifier).loadInventory();
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
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Item Management'),
        backgroundColor: CarmenColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemForm(null),
        backgroundColor: CarmenColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
      body: menuState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar - Same style as POS
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

                // Category filter
                if (menuState.categories.isNotEmpty)
                  _buildCategoryFilter(menuState),
                
                const SizedBox(height: 8),

                // Items list
                Expanded(
                  child: _buildItemsList(menuState, inventoryState),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter(MenuState menuState) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: menuState.categories.length + 2, // +1 for All, +1 for Add
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" chip
            final isSelected = _selectedCategoryId == null;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategoryId = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? CarmenColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'All',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }
          
          // "+Add Category" button at the end
          if (index == menuState.categories.length + 1) {
            return GestureDetector(
              onTap: _showAddCategoryDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CarmenColors.primaryGreen, style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: CarmenColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Add Category',
                      style: TextStyle(
                        color: CarmenColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final category = menuState.categories[index - 1];
          final isSelected = _selectedCategoryId == category.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryId = category.id),
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

  Widget _buildItemsList(MenuState menuState, InventoryState inventoryState) {
    // Filter by selected category and search query
    var items = menuState.items;
    if (_selectedCategoryId != null) {
      items = items.where((i) => i.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(_searchQuery)).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first item',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final stock = inventoryState.items.firstWhere(
            (inv) => inv.menuItemId == item.id,
            orElse: () => Inventory(
              id: '',
              menuItemId: item.id,
              currentStock: 0,
              updatedAt: DateTime.now(),
            ),
          );
          return _buildItemCard(item, stock, menuState);
        },
      ),
    );
  }

  Widget _buildItemCard(MenuItem item, Inventory stock, MenuState menuState) {
    final isLowStock = item.trackInventory && stock.currentStock <= stock.lowStockThreshold;
    final categoryName = menuState.categories
        .firstWhere((c) => c.id == item.categoryId, orElse: () => menuState.categories.first)
        .name;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openItemForm(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Item photo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: CarmenColors.lightCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? (item.imageUrl!.startsWith('http')
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : Image.file(File(item.imageUrl!), fit: BoxFit.cover))
                      : Icon(Icons.restaurant, color: Colors.grey[400], size: 28),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HIDDEN',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (isLowStock)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LOW',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CarmenColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Availability toggle
              Switch(
                value: item.isAvailable,
                onChanged: (val) => _toggleAvailability(item, val),
                activeColor: CarmenColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await ref.read(menuProvider.notifier).loadMenu();
    await ref.read(inventoryProvider.notifier).loadInventory();
  }

  void _openItemForm(MenuItem? item) {
    final categories = ref.read(menuProvider).categories;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemFormModal(
          item: item,
          categories: categories,
        ),
      ),
    ).then((saved) {
      if (saved == true) _refresh();
    });
  }

  void _toggleAvailability(MenuItem item, bool isAvailable) {
    ref.read(menuProvider.notifier).toggleItemAvailability(item.id, isAvailable);
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Hot Drinks, Pastries',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a category name')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        try {
                          final menuService = ref.read(menuServiceProvider);
                          final now = DateTime.now();
                          final categories = ref.read(menuProvider).categories;
                          
                          final newCategory = Category(
                            id: const Uuid().v4(),
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            sortOrder: categories.length,
                            isActive: true,
                            createdAt: now,
                            updatedAt: now,
                          );

                          await menuService.createCategory(newCategory);
                          await ref.read(menuProvider.notifier).loadMenu();

                          if (mounted) Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Category "${newCategory.name}" created'),
                              backgroundColor: CarmenColors.successGreen,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to create category: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CarmenColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
