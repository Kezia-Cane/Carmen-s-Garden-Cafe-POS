import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory.freezed.dart';
part 'inventory.g.dart';

/// Inventory model
@freezed
class Inventory with _$Inventory {
  const factory Inventory({
    required String id,
    @JsonKey(name: 'menu_item_id') required String menuItemId,
    @JsonKey(name: 'current_stock') required int currentStock,
    @JsonKey(name: 'low_stock_threshold') @Default(10) int lowStockThreshold,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Inventory;

  factory Inventory.fromJson(Map<String, dynamic> json) => _$InventoryFromJson(json);
  
  // Helper to check if stock is low
  const Inventory._();
  bool get isLowStock => currentStock <= lowStockThreshold;
}

/// Inventory adjustment reason
enum InventoryAdjustmentReason {
  restock,
  sale,
  waste,
  damage,
  countCorrection,
  returned,
}

/// Inventory transaction model
@freezed
class InventoryTransaction with _$InventoryTransaction {
  const factory InventoryTransaction({
    required String id,
    @JsonKey(name: 'inventory_id') required String inventoryId,
    @JsonKey(name: 'quantity_change') required int quantityChange,
    required InventoryAdjustmentReason reason,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default(false) @JsonKey(includeToJson: false) bool isSynced,
  }) = _InventoryTransaction;

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) => _$InventoryTransactionFromJson(json);
}
