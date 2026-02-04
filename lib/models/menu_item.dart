import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

/// Menu item model
@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String categoryId,
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    @Default(true) bool isAvailable,
    @Default(false) bool trackInventory,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
}

/// Modifier option (e.g., "Small" with +$0.00, "Large" with +$0.50)
@freezed
class ModifierOption with _$ModifierOption {
  const factory ModifierOption({
    required String name,
    @Default(0.0) double priceAdjustment,
  }) = _ModifierOption;

  factory ModifierOption.fromJson(Map<String, dynamic> json) => _$ModifierOptionFromJson(json);
}

/// Item modifier (e.g., Size, Milk Type, Sugar Level)
@freezed
class ItemModifier with _$ItemModifier {
  const factory ItemModifier({
    required String id,
    required String menuItemId,
    required String name,
    required String type, // 'single_select', 'multi_select'
    required List<ModifierOption> options,
    @Default(false) bool isRequired,
    required DateTime createdAt,
  }) = _ItemModifier;

  factory ItemModifier.fromJson(Map<String, dynamic> json) => _$ItemModifierFromJson(json);
}
