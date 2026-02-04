import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local/menu_dao.dart';
import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/menu_item.dart';

/// Sample data seeder for Carmen's Garden Cafe
class SampleDataSeeder {
  final MenuDao _menuDao = MenuDao();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<bool> hasData() async {
    final categories = await _menuDao.getCategories();
    return categories.isNotEmpty;
  }

  Future<void> forceReseed() async {
    final db = await _dbHelper.database;
    await db.delete('item_modifiers');
    await db.delete('inventory');
    await db.delete('menu_items');
    await db.delete('categories');
    await _seedAll();
  }

  Future<void> seedAll() async {
    if (await hasData()) return;
    await _seedAll();
  }

  Future<void> _seedAll() async {
    final now = DateTime.now();

    // Create categories (removed "(Iced)" from names)
    final categories = [
      _createCategory('Classic Coffee', 'Espresso-based coffee drinks', 1, now),
      _createCategory('Signature', 'Our specialty iced coffee creations', 2, now),
      _createCategory('Non-Coffee', 'Refreshing non-coffee iced drinks', 3, now),
      _createCategory('Matcha Series', 'Premium matcha beverages', 4, now),
      _createCategory('Refreshments', 'Fresh and fizzy refreshments', 5, now),
      _createCategory('Frappuccino - Coffee Based', 'Blended coffee drinks', 6, now),
      _createCategory('Frappuccino - Non-Coffee', 'Blended non-coffee drinks', 7, now),
      _createCategory('Starters', 'Appetizers and sides', 8, now),
      _createCategory('Pizza', 'Fresh baked pizzas', 9, now),
      _createCategory('Pasta', 'Italian pasta dishes', 10, now),
      _createCategory('Chicken', 'Chicken specialties', 11, now),
      _createCategory('Ala Carte', 'Individual servings', 12, now),
      _createCategory('Waffles', 'Sweet waffle treats', 13, now),
    ];

    for (final category in categories) {
      await _menuDao.createCategory(category);
    }

    await _seedClassicCoffee(categories[0].id, now);
    await _seedSignature(categories[1].id, now);
    await _seedNonCoffee(categories[2].id, now);
    await _seedMatchaSeries(categories[3].id, now);
    await _seedRefreshments(categories[4].id, now);
    await _seedFrappuccinoCoffee(categories[5].id, now);
    await _seedFrappuccinoNonCoffee(categories[6].id, now);
    await _seedStarters(categories[7].id, now);
    await _seedPizza(categories[8].id, now);
    await _seedPasta(categories[9].id, now);
    await _seedChicken(categories[10].id, now);
    await _seedAlaCarte(categories[11].id, now);
    await _seedWaffles(categories[12].id, now);
  }

  Category _createCategory(String name, String description, int sortOrder, DateTime now) {
    return Category(
      id: _uuid.v4(),
      name: name,
      description: description,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Helper to create item with modifiers
  Future<void> _createItemWithVariants(
    String categoryId,
    String name,
    List<Map<String, dynamic>> variants,
    DateTime now,
    int sortOrder,
  ) async {
    // Use lowest price as base price
    double basePrice = variants.map((v) => v['price'] as double).reduce((a, b) => a < b ? a : b);
    
    final item = MenuItem(
      id: _uuid.v4(),
      categoryId: categoryId,
      name: name,
      price: basePrice,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await _menuDao.createMenuItem(item);

    // Create variant modifier with all options
    final options = variants.map((v) {
      String label;
      if (v.containsKey('type') && v.containsKey('size')) {
        label = '${v['type']} ${v['size']}';
      } else if (v.containsKey('size')) {
        label = v['size'] as String;
      } else if (v.containsKey('name')) {
        label = v['name'] as String;
      } else {
        label = 'Default';
      }
      return ModifierOption(
        name: label,
        priceAdjustment: (v['price'] as double) - basePrice,
      );
    }).toList();

    final modifier = ItemModifier(
      id: _uuid.v4(),
      menuItemId: item.id,
      name: 'Variant',
      type: 'single_select',
      options: options,
      isRequired: true,
      createdAt: now,
    );
    await _menuDao.createModifier(modifier);
  }

  Future<void> _createSimpleItem(
    String categoryId,
    String name,
    double price,
    DateTime now,
    int sortOrder, {
    String? size,
  }) async {
    final item = MenuItem(
      id: _uuid.v4(),
      categoryId: categoryId,
      name: name,
      description: size != null ? size : null,
      price: price,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await _menuDao.createMenuItem(item);
  }

  // ============ CLASSIC COFFEE ============
  Future<void> _seedClassicCoffee(String categoryId, DateTime now) async {
    int order = 0;
    
    await _createItemWithVariants(categoryId, 'Americano', [
      {'type': 'Hot', 'size': '8oz', 'price': 85.0},
      {'type': 'Hot', 'size': '12oz', 'price': 95.0},
      {'type': 'Iced', 'size': '12oz', 'price': 95.0},
      {'type': 'Iced', 'size': '16oz', 'price': 105.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Cafe Latte', [
      {'type': 'Hot', 'size': '8oz', 'price': 95.0},
      {'type': 'Hot', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '16oz', 'price': 130.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Caramel Macchiato', [
      {'type': 'Hot', 'size': '8oz', 'price': 95.0},
      {'type': 'Hot', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '16oz', 'price': 140.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Spanish Latte', [
      {'type': 'Hot', 'size': '8oz', 'price': 95.0},
      {'type': 'Hot', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '16oz', 'price': 130.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Cafe Mocha', [
      {'type': 'Hot', 'size': '8oz', 'price': 95.0},
      {'type': 'Hot', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '16oz', 'price': 130.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Cappuccino', [
      {'type': 'Hot', 'size': '8oz', 'price': 95.0},
      {'type': 'Hot', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '16oz', 'price': 130.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'White Mocha', [
      {'type': 'Hot', 'size': '8oz', 'price': 95.0},
      {'type': 'Hot', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '12oz', 'price': 110.0},
      {'type': 'Iced', 'size': '16oz', 'price': 130.0},
    ], now, order++);
  }

  // ============ SIGNATURE (no more "(Iced)") ============
  Future<void> _seedSignature(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Dulce De Leche', 160.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Slowdown Spanish Latte', 170.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Campfire Cloud', 170.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Tiramisu Latte', 160.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Biscoff Crumb', 175.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Black Sunkist', 140.0, now, order++, size: '16oz');
  }

  // ============ NON-COFFEE ============
  Future<void> _seedNonCoffee(String categoryId, DateTime now) async {
    int order = 0;
    
    await _createItemWithVariants(categoryId, 'Strawberry', [
      {'size': '12oz', 'price': 110.0},
      {'size': '16oz', 'price': 130.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Chocolate', [
      {'size': '12oz', 'price': 110.0},
      {'size': '16oz', 'price': 130.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Oreo Strawberry', [
      {'size': '12oz', 'price': 110.0},
      {'size': '16oz', 'price': 130.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Cookies & Cream', [
      {'size': '12oz', 'price': 110.0},
      {'size': '16oz', 'price': 130.0},
    ], now, order++);
  }

  // ============ MATCHA SERIES ============
  Future<void> _seedMatchaSeries(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Sea Salt Matcha', 140.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Ceremonial Matcha', 120.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Matcha Honey Oat', 170.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Fragaria Matcha', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Matcha Fusion', 140.0, now, order++, size: '16oz');
  }

  // ============ REFRESHMENTS ============
  Future<void> _seedRefreshments(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Lemonade', 125.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Strawberry Fizz', 130.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Blueberry Fizz', 130.0, now, order++, size: '16oz');
  }

  // ============ FRAPPUCCINO - COFFEE BASED ============
  Future<void> _seedFrappuccinoCoffee(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Java Chip', 160.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Biscoff', 170.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Mocha', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Caramel', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Vanilla', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Salted Caramel', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'White Mocha', 150.0, now, order++, size: '16oz');
  }

  // ============ FRAPPUCCINO - NON-COFFEE ============
  Future<void> _seedFrappuccinoNonCoffee(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Matcha', 160.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Chocolate', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Cookies & Cream', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Chocolate Chip Cream', 160.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Zesty Chocolate Ground', 170.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Strawberry', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Blueberry', 150.0, now, order++, size: '16oz');
    await _createSimpleItem(categoryId, 'Mixed Berries', 150.0, now, order++, size: '16oz');
  }

  // ============ STARTERS ============
  Future<void> _seedStarters(String categoryId, DateTime now) async {
    int order = 0;
    
    await _createItemWithVariants(categoryId, 'Fries', [
      {'name': 'Plain', 'price': 99.0},
      {'name': 'Cheese', 'price': 119.0},
      {'name': 'Sour Cream', 'price': 119.0},
      {'name': 'BBQ', 'price': 119.0},
    ], now, order++);

    await _createItemWithVariants(categoryId, 'Quesadilla', [
      {'name': 'Cheese', 'price': 149.0},
      {'name': 'Beef', 'price': 189.0},
    ], now, order++);

    await _createSimpleItem(categoryId, 'Nachos', 159.0, now, order++);
  }

  // ============ PIZZA ============
  Future<void> _seedPizza(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'All Cheese', 299.0, now, order++);
    await _createSimpleItem(categoryId, 'Hawaiian', 329.0, now, order++);
    await _createSimpleItem(categoryId, 'Ham & Cheese', 319.0, now, order++);
    await _createSimpleItem(categoryId, 'Pepperoni', 349.0, now, order++);
  }

  // ============ PASTA ============
  Future<void> _seedPasta(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Lasagna', 269.0, now, order++);
    await _createSimpleItem(categoryId, 'Creamy Beef Carbonara', 249.0, now, order++);
  }

  // ============ CHICKEN ============
  Future<void> _seedChicken(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Whole Chicken', 499.0, now, order++);
    
    // Half Chicken with flavor options
    await _createItemWithVariants(categoryId, 'Half Chicken', [
      {'name': 'Buffalo', 'price': 279.0},
      {'name': 'Garlic Butter', 'price': 279.0},
      {'name': 'Original', 'price': 269.0},
    ], now, order++);
    
    await _createSimpleItem(categoryId, 'Grilled Quarter', 169.0, now, order++);
  }

  // ============ ALA CARTE ============
  Future<void> _seedAlaCarte(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Hito (Fried, 2pcs)', 199.0, now, order++);
  }

  // ============ WAFFLES ============
  Future<void> _seedWaffles(String categoryId, DateTime now) async {
    int order = 0;
    await _createSimpleItem(categoryId, 'Chocolate Cookie', 149.0, now, order++);
    await _createSimpleItem(categoryId, 'Strawberry', 139.0, now, order++);
    await _createSimpleItem(categoryId, 'Caramel Almond', 159.0, now, order++);
  }
}

/// Provider for sample data seeder
final sampleDataSeederProvider = Provider<SampleDataSeeder>((ref) {
  return SampleDataSeeder();
});
