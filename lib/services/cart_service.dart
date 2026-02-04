import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_item.dart';
import '../models/order.dart';


/// Cart item with quantity and selected modifiers
class CartItem {
  final MenuItem menuItem;
  final int quantity;
  final List<SelectedModifier> modifiers;
  final String? specialInstructions;

  const CartItem({
    required this.menuItem,
    required this.quantity,
    this.modifiers = const [],
    this.specialInstructions,
  });

  /// Calculate total price including modifiers
  double get totalPrice {
    double modifierTotal = modifiers.fold(
      0.0,
      (sum, mod) => sum + mod.priceAdjustment,
    );
    return (menuItem.price + modifierTotal) * quantity;
  }

  /// Create copy with updated quantity
  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    List<SelectedModifier>? modifiers,
    String? specialInstructions,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      modifiers: modifiers ?? this.modifiers,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

/// Cart state
class CartState {
  final List<CartItem> items;
  final String? customerName;

  const CartState({
    this.items = const [],
    this.customerName,
  });

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Total number of items (considering quantities)
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal before tax
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Tax amount - Removed as requested
  double get taxAmount => 0.0;

  /// Total (no tax)
  double get total => subtotal;

  CartState copyWith({
    List<CartItem>? items,
    String? customerName,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
    );
  }
}

/// Cart state notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  final _uuid = const Uuid();

  /// Add item to cart
  void addItem(
    MenuItem menuItem, {
    int quantity = 1,
    List<SelectedModifier> modifiers = const [],
    String? specialInstructions,
  }) {
    // Check if same item with same modifiers exists
    final existingIndex = state.items.indexWhere(
      (item) =>
          item.menuItem.id == menuItem.id &&
          _modifiersEqual(item.modifiers, modifiers) &&
          item.specialInstructions == specialInstructions,
    );

    if (existingIndex >= 0) {
      // Update quantity of existing item
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            menuItem: menuItem,
            quantity: quantity,
            modifiers: modifiers,
            specialInstructions: specialInstructions,
          ),
        ],
      );
    }
  }

  /// Add item with variant modifiers from POS selection
  void addItemWithModifiers(
    MenuItem menuItem,
    List<String> selectedModifierNames,
    double totalPrice,
  ) {
    // Calculate price adjustment from base price
    final priceAdjustment = totalPrice - menuItem.price;
    
    // Create selected modifier with combined variant info
    final modifiers = selectedModifierNames.isNotEmpty
        ? [
            SelectedModifier(
              name: 'Variant',
              selectedOption: selectedModifierNames.join(' / '),
              priceAdjustment: priceAdjustment,
            ),
          ]
        : <SelectedModifier>[];

    addItem(menuItem, modifiers: modifiers);
  }

  /// Update item quantity
  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= state.items.length) return;

    if (quantity <= 0) {
      removeItem(index);
      return;
    }

    final updatedItems = [...state.items];
    updatedItems[index] = updatedItems[index].copyWith(quantity: quantity);
    state = state.copyWith(items: updatedItems);
  }

  /// Increment item quantity
  void incrementQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    updateQuantity(index, state.items[index].quantity + 1);
  }

  /// Decrement item quantity
  void decrementQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    updateQuantity(index, state.items[index].quantity - 1);
  }

  /// Remove item from cart
  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updatedItems = [...state.items];
    updatedItems.removeAt(index);
    state = state.copyWith(items: updatedItems);
  }

  /// Set customer name
  void setCustomerName(String? name) {
    state = state.copyWith(customerName: name);
  }

  /// Clear cart
  void clear() {
    state = const CartState();
  }

  /// Convert cart to order items
  List<OrderItem> toOrderItems(String orderId) {
    final now = DateTime.now();
    return state.items.map((cartItem) {
      return OrderItem(
        id: _uuid.v4(),
        orderId: orderId,
        menuItemId: cartItem.menuItem.id,
        name: cartItem.menuItem.name,
        quantity: cartItem.quantity,
        unitPrice: cartItem.menuItem.price +
            cartItem.modifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment),
        totalPrice: cartItem.totalPrice,
        modifiers: cartItem.modifiers,
        specialInstructions: cartItem.specialInstructions,
        createdAt: now,
      );
    }).toList();
  }

  /// Check if modifiers are equal
  bool _modifiersEqual(List<SelectedModifier> a, List<SelectedModifier> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name || a[i].selectedOption != b[i].selectedOption) {
        return false;
      }
    }
    return true;
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
