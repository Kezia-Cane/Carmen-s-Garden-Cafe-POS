import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local/menu_dao.dart';
import '../models/menu_item.dart';
import '../models/category.dart';
import '../services/sync_service.dart';
import '../services/activity_log_service.dart';

/// Menu service for loading and managing menu data
class MenuService {
  final MenuDao _menuDao;
  final SyncService? _syncService;
  final ActivityLogService? _activityLogService;

  MenuService({
    MenuDao? menuDao,
    SyncService? syncService,
    ActivityLogService? activityLogService,
  })  : _menuDao = menuDao ?? MenuDao(),
        _syncService = syncService,
        _activityLogService = activityLogService;

  /// Get all categories
  Future<List<Category>> getCategories({bool activeOnly = true}) async {
    return _menuDao.getCategories(activeOnly: activeOnly);
  }

  /// Get menu items by category
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    bool availableOnly = true,
  }) async {
    return _menuDao.getMenuItems(
      categoryId: categoryId,
      availableOnly: availableOnly,
    );
  }

  /// Get menu item by ID
  Future<MenuItem?> getMenuItemById(String id) async {
    return _menuDao.getMenuItemById(id);
  }

  /// Get modifiers for a menu item
  Future<List<ItemModifier>> getModifiersForItem(String menuItemId) async {
    return _menuDao.getModifiersForItem(menuItemId);
  }

  /// Toggle item availability (86'd)
  Future<void> setItemAvailability(String id, bool isAvailable) async {
    await _menuDao.setItemAvailability(id, isAvailable);
    _syncService?.syncAll();
  }

  /// Create new menu item
  Future<MenuItem> createItem(MenuItem item, {String? categoryName}) async {
    final result = await _menuDao.createMenuItem(item);
    _activityLogService?.logItemAdded(item.name, categoryName ?? 'Unknown');
    
    // Sync to cloud
    _syncService?.syncMenuItem({
      'id': item.id,
      'category_id': item.categoryId,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'image_url': item.imageUrl,
      'is_available': item.isAvailable,
      'track_inventory': item.trackInventory,
      'sort_order': item.sortOrder,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    });
    _syncService?.syncAll();
    return result;
  }

  /// Update existing menu item
  Future<MenuItem> updateItem(MenuItem item, {String? changes}) async {
    final result = await _menuDao.updateMenuItem(item);
    _activityLogService?.logItemUpdated(item.name, changes ?? 'Updated');
    
    // Sync to cloud
    _syncService?.syncMenuItem({
      'id': item.id,
      'category_id': item.categoryId,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'image_url': item.imageUrl,
      'is_available': item.isAvailable,
      'track_inventory': item.trackInventory,
      'sort_order': item.sortOrder,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    });
    _syncService?.syncAll();
    return result;
  }

  /// Delete menu item
  Future<void> deleteItem(String id, {String? itemName}) async {
    _activityLogService?.logItemDeleted(itemName ?? 'Item');
    await _menuDao.deleteMenuItem(id);
    
    // Delete from cloud
    _syncService?.deleteMenuItemFromCloud(id);
    _syncService?.syncAll();
  }

  /// Create new category
  Future<Category> createCategory(Category category) async {
    final result = await _menuDao.createCategory(category);
    _syncService?.syncAll();
    return result;
  }

  /// Create modifier for a menu item
  Future<ItemModifier> createModifier(ItemModifier modifier) async {
    final result = await _menuDao.createModifier(modifier);
    _syncService?.syncAll();
    return result;
  }

  /// Update modifier
  Future<ItemModifier> updateModifier(ItemModifier modifier) async {
    final result = await _menuDao.updateModifier(modifier);
    _syncService?.syncAll();
    return result;
  }

  /// Delete modifier
  Future<void> deleteModifier(String modifierId) async {
    await _menuDao.deleteModifier(modifierId);
    _syncService?.syncAll();
  }

  /// Replace all menu data (from cloud sync)
  Future<void> syncMenuFromCloud({
    required List<Category> categories,
    required List<MenuItem> items,
    required List<ItemModifier> modifiers,
  }) async {
    await _menuDao.replaceAllMenuData(
      categories: categories,
      items: items,
      modifiers: modifiers,
    );
  }
}

/// Menu state for POS UI
class MenuState {
  final List<Category> categories;
  final List<MenuItem> items;
  final List<ItemModifier> modifiers;
  final String? selectedCategoryId;
  final bool isLoading;
  final String? error;

  const MenuState({
    this.categories = const [],
    this.items = const [],
    this.modifiers = const [],
    this.selectedCategoryId,
    this.isLoading = false,
    this.error,
  });

  /// Get items for selected category
  List<MenuItem> get filteredItems {
    if (selectedCategoryId == null) return items;
    return items.where((item) => item.categoryId == selectedCategoryId).toList();
  }

  MenuState copyWith({
    List<Category>? categories,
    List<MenuItem>? items,
    List<ItemModifier>? modifiers,
    String? selectedCategoryId,
    bool? isLoading,
    String? error,
  }) {
    return MenuState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      modifiers: modifiers ?? this.modifiers,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Menu notifier for UI
class MenuNotifier extends StateNotifier<MenuState> {
  final MenuService _menuService;

  MenuNotifier(this._menuService) : super(const MenuState());

  /// Load menu data
  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _menuService.getCategories();
      final items = await _menuService.getMenuItems(availableOnly: false);
      
      // Load all modifiers for all items
      final List<ItemModifier> allModifiers = [];
      for (final item in items) {
        final itemModifiers = await _menuService.getModifiersForItem(item.id);
        allModifiers.addAll(itemModifiers);
      }
      
      String? selectedCategory = state.selectedCategoryId;
      if (selectedCategory == null && categories.isNotEmpty) {
        selectedCategory = categories.first.id;
      } else if (selectedCategory != null && !categories.any((c) => c.id == selectedCategory)) {
        selectedCategory = categories.isNotEmpty ? categories.first.id : null;
      }
      
      state = state.copyWith(
        categories: categories,
        items: items,
        modifiers: allModifiers,
        selectedCategoryId: selectedCategory,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select category
  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  /// Toggle item availability
  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    // Optimistic update
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isAvailable: isAvailable);
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);

    // Perform actual update
    await _menuService.setItemAvailability(itemId, isAvailable);
  }

  /// Refresh menu
  Future<void> refresh() async {
    await loadMenu();
  }
}

/// Providers
final menuServiceProvider = Provider<MenuService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final activityLogService = ref.watch(activityLogServiceProvider);
  return MenuService(
    syncService: syncService,
    activityLogService: activityLogService,
  );
});

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  return MenuNotifier(menuService);
});
