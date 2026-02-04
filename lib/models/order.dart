import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Order status enum
enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled,
  voided,
}

/// Order model
@freezed
class Order with _$Order {
  @JsonSerializable(explicitToJson: true) // Keep explicitToJson for nested items
  const factory Order({
    required String id,
    @JsonKey(name: 'order_number') required int orderNumber,
    @JsonKey(name: 'customer_name') String? customerName,
    @Default(OrderStatus.pending) OrderStatus status,
    required double subtotal,
    @JsonKey(name: 'tax_amount') required double taxAmount,
    @JsonKey(name: 'total_amount') required double totalAmount,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @Default(false) @JsonKey(includeToJson: false) bool isSynced,
    @Default([]) @JsonKey(includeToJson: false) List<OrderItem> items,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

/// Selected modifier for an order item
@freezed
class SelectedModifier with _$SelectedModifier {
  const factory SelectedModifier({
    required String name,
    @JsonKey(name: 'selected_option') required String selectedOption,
    @JsonKey(name: 'price_adjustment') @Default(0.0) double priceAdjustment,
  }) = _SelectedModifier;

  factory SelectedModifier.fromJson(Map<String, dynamic> json) => _$SelectedModifierFromJson(json);
}

/// Order item model
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'menu_item_id') required String menuItemId,
    required String name,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'total_price') required double totalPrice,
    @Default([]) List<SelectedModifier> modifiers,
    @JsonKey(name: 'special_instructions') String? specialInstructions,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
}
