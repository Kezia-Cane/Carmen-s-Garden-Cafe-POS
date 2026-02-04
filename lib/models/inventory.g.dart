// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InventoryImpl _$$InventoryImplFromJson(Map<String, dynamic> json) =>
    _$InventoryImpl(
      id: json['id'] as String,
      menuItemId: json['menu_item_id'] as String,
      currentStock: (json['current_stock'] as num).toInt(),
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 10,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$InventoryImplToJson(_$InventoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'menu_item_id': instance.menuItemId,
      'current_stock': instance.currentStock,
      'low_stock_threshold': instance.lowStockThreshold,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_$InventoryTransactionImpl _$$InventoryTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$InventoryTransactionImpl(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      quantityChange: (json['quantity_change'] as num).toInt(),
      reason: $enumDecode(_$InventoryAdjustmentReasonEnumMap, json['reason']),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$InventoryTransactionImplToJson(
        _$InventoryTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'inventory_id': instance.inventoryId,
      'quantity_change': instance.quantityChange,
      'reason': _$InventoryAdjustmentReasonEnumMap[instance.reason]!,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$InventoryAdjustmentReasonEnumMap = {
  InventoryAdjustmentReason.restock: 'restock',
  InventoryAdjustmentReason.sale: 'sale',
  InventoryAdjustmentReason.waste: 'waste',
  InventoryAdjustmentReason.damage: 'damage',
  InventoryAdjustmentReason.countCorrection: 'countCorrection',
  InventoryAdjustmentReason.returned: 'returned',
};
