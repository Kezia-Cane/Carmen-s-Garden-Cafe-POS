import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../database_helper.dart';
import '../../../models/menu_item.dart';
import '../../../models/category.dart';

/// Menu Data Access Object
/// Handles menu items and categories
class MenuDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============ CATEGORIES ============

  // Create category
  Future<Category> createCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.insert('categories', {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'sort_order': category.sortOrder,
      'is_active': category.isActive ? 1 : 0,
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': category.updatedAt.toIso8601String(),
    });
    return category;
  }

  // Get all categories
  Future<List<Category>> getCategories({bool activeOnly = true}) async {
    final db = await _dbHelper.database;
    
    String? where;
    if (activeOnly) {
      where = 'is_active = 1';
    }
    
    final maps = await db.query(
      'categories',
      where: where,
      orderBy: 'sort_order ASC',
    );

    return maps.map((map) => Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      sortOrder: map['sort_order'] as int,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  // ============ MENU ITEMS ============

  // Create menu item
  Future<MenuItem> createMenuItem(MenuItem item) async {
    final db = await _dbHelper.database;
    await db.insert('menu_items', {
      'id': item.id,
      'category_id': item.categoryId,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'image_url': item.imageUrl,
      'is_available': item.isAvailable ? 1 : 0,
      'track_inventory': item.trackInventory ? 1 : 0,
      'sort_order': item.sortOrder,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    });
    return item;
  }

  // Get all menu items
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    bool availableOnly = true,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (availableOnly) {
      whereClause += ' AND is_available = 1';
    }

    final maps = await db.query(
      'menu_items',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'sort_order ASC',
    );

    return maps.map((map) => MenuItem(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
      isAvailable: (map['is_available'] as int) == 1,
      trackInventory: (map['track_inventory'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  // Get menu item by ID
  Future<MenuItem?> getMenuItemById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return MenuItem(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
      isAvailable: (map['is_available'] as int) == 1,
      trackInventory: (map['track_inventory'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Update menu item availability
  Future<void> setItemAvailability(String id, bool isAvailable) async {
    final db = await _dbHelper.database;
    await db.update(
      'menu_items',
      {
        'is_available': isAvailable ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update menu item
  Future<MenuItem> updateMenuItem(MenuItem item) async {
    final db = await _dbHelper.database;
    await db.update(
      'menu_items',
      {
        'category_id': item.categoryId,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'is_available': item.isAvailable ? 1 : 0,
        'track_inventory': item.trackInventory ? 1 : 0,
        'sort_order': item.sortOrder,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
    return item;
  }

  // Delete menu item
  Future<void> deleteMenuItem(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ MODIFIERS ============

  // Get modifiers for a menu item
  Future<List<ItemModifier>> getModifiersForItem(String menuItemId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'item_modifiers',
      where: 'menu_item_id = ?',
      whereArgs: [menuItemId],
    );

    return maps.map((map) {
      final optionsList = jsonDecode(map['options'] as String) as List;
      final options = optionsList
          .map((o) => ModifierOption.fromJson(o as Map<String, dynamic>))
          .toList();

      return ItemModifier(
        id: map['id'] as String,
        menuItemId: map['menu_item_id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        options: options,
        isRequired: (map['is_required'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  // Create modifier for menu item
  Future<ItemModifier> createModifier(ItemModifier modifier) async {
    final db = await _dbHelper.database;
    await db.insert('item_modifiers', {
      'id': modifier.id,
      'menu_item_id': modifier.menuItemId,
      'name': modifier.name,
      'type': modifier.type,
      'options': jsonEncode(modifier.options.map((o) => o.toJson()).toList()),
      'is_required': modifier.isRequired ? 1 : 0,
      'created_at': modifier.createdAt.toIso8601String(),
    });
    return modifier;
  }

  // Update modifier
  Future<ItemModifier> updateModifier(ItemModifier modifier) async {
    final db = await _dbHelper.database;
    await db.update(
      'item_modifiers',
      {
        'name': modifier.name,
        'type': modifier.type,
        'options': jsonEncode(modifier.options.map((o) => o.toJson()).toList()),
        'is_required': modifier.isRequired ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [modifier.id],
    );
    return modifier;
  }

  // Delete modifier
  Future<void> deleteModifier(String modifierId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'item_modifiers',
      where: 'id = ?',
      whereArgs: [modifierId],
    );
  }

  // Delete all modifiers for a menu item
  Future<void> deleteModifiersForItem(String menuItemId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'item_modifiers',
      where: 'menu_item_id = ?',
      whereArgs: [menuItemId],
    );
  }

  // ============ BULK OPERATIONS (for sync) ============

  // Replace all menu data (from cloud sync)
  Future<void> replaceAllMenuData({
    required List<Category> categories,
    required List<MenuItem> items,
    required List<ItemModifier> modifiers,
  }) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('item_modifiers');
      await txn.delete('menu_items');
      await txn.delete('categories');
      
      // Insert categories
      for (final category in categories) {
        await txn.insert('categories', {
          'id': category.id,
          'name': category.name,
          'description': category.description,
          'sort_order': category.sortOrder,
          'is_active': category.isActive ? 1 : 0,
          'created_at': category.createdAt.toIso8601String(),
          'updated_at': category.updatedAt.toIso8601String(),
        });
      }
      
      // Insert items
      for (final item in items) {
        await txn.insert('menu_items', {
          'id': item.id,
          'category_id': item.categoryId,
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'image_url': item.imageUrl,
          'is_available': item.isAvailable ? 1 : 0,
          'track_inventory': item.trackInventory ? 1 : 0,
          'sort_order': item.sortOrder,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': item.updatedAt.toIso8601String(),
        });
      }
      
      // Insert modifiers
      for (final modifier in modifiers) {
        await txn.insert('item_modifiers', {
          'id': modifier.id,
          'menu_item_id': modifier.menuItemId,
          'name': modifier.name,
          'type': modifier.type,
          'options': jsonEncode(modifier.options.map((o) => o.toJson()).toList()),
          'is_required': modifier.isRequired ? 1 : 0,
          'created_at': modifier.createdAt.toIso8601String(),
        });
      }
    });
  }
}
