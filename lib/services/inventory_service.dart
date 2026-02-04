import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local/inventory_dao.dart';
import '../models/inventory.dart';
import '../services/sync_service.dart';

/// Inventory service for stock management
class InventoryService {
  final InventoryDao _inventoryDao = InventoryDao();
  final SyncService? _syncService;

  InventoryService({SyncService? syncService}) : _syncService = syncService;

  /// Get inventory for a menu item
  Future<Inventory> getInventoryForItem(String menuItemId) async {
    return _inventoryDao.getOrCreateInventory(menuItemId);
  }

  /// Get all inventory items
  Future<List<Inventory>> getAllInventory() async {
    return _inventoryDao.getAllInventory();
  }

  /// Get items with low stock
  Future<List<Inventory>> getLowStockItems() async {
    return _inventoryDao.getLowStockItems();
  }

  /// Restock item
  Future<Inventory> restockItem({
    required String menuItemId,
    required int quantity,
    String? notes,
  }) async {
    final result = await _inventoryDao.adjustStock(
      menuItemId: menuItemId,
      adjustment: quantity,
      reason: InventoryAdjustmentReason.restock,
      notes: notes,
    );
    _syncService?.syncAll();
    return result;
  }

  /// Deduct stock (for sales)
  Future<Inventory> deductForSale({
    required String menuItemId,
    required int quantity,
  }) async {
    final result = await _inventoryDao.adjustStock(
      menuItemId: menuItemId,
      adjustment: -quantity,
      reason: InventoryAdjustmentReason.sale,
    );
    _syncService?.syncAll();
    return result;
  }

  /// Adjust stock (for corrections, waste, damage)
  Future<Inventory> adjustStock({
    required String menuItemId,
    required int adjustment,
    required InventoryAdjustmentReason reason,
    String? notes,
  }) async {
    final result = await _inventoryDao.adjustStock(
      menuItemId: menuItemId,
      adjustment: adjustment,
      reason: reason,
      notes: notes,
    );
    _syncService?.syncAll();
    return result;
  }

  /// Set absolute stock level
  Future<Inventory> setStockLevel({
    required String menuItemId,
    required int newStock,
  }) async {
    final result = await _inventoryDao.updateStock(
      menuItemId: menuItemId,
      newStock: newStock,
    );
    _syncService?.syncAll();
    return result;
  }

  /// Get transaction history for an item
  Future<List<InventoryTransaction>> getTransactionHistory({
    required String inventoryId,
    int limit = 50,
  }) async {
    return _inventoryDao.getTransactions(
      inventoryId: inventoryId,
      limit: limit,
    );
  }

  /// Get unsynced transactions
  Future<List<InventoryTransaction>> getUnsyncedTransactions() async {
    return _inventoryDao.getUnsyncedTransactions();
  }
}

/// Inventory state for UI
class InventoryState {
  final List<Inventory> items;
  final List<Inventory> lowStockItems;
  final bool isLoading;
  final String? error;

  const InventoryState({
    this.items = const [],
    this.lowStockItems = const [],
    this.isLoading = false,
    this.error,
  });

  /// Count of low stock items
  int get lowStockCount => lowStockItems.length;

  InventoryState copyWith({
    List<Inventory>? items,
    List<Inventory>? lowStockItems,
    bool? isLoading,
    String? error,
  }) {
    return InventoryState(
      items: items ?? this.items,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Inventory notifier for UI
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryService _inventoryService;

  InventoryNotifier(this._inventoryService) : super(const InventoryState());

  /// Load all inventory
  Future<void> loadInventory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _inventoryService.getAllInventory();
      final lowStock = await _inventoryService.getLowStockItems();
      state = state.copyWith(
        items: items,
        lowStockItems: lowStock,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Restock an item
  Future<void> restockItem({
    required String menuItemId,
    required int quantity,
    String? notes,
  }) async {
    try {
      await _inventoryService.restockItem(
        menuItemId: menuItemId,
        quantity: quantity,
        notes: notes,
      );
      await loadInventory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Adjust stock
  Future<void> adjustStock({
    required String menuItemId,
    required int adjustment,
    required InventoryAdjustmentReason reason,
    String? notes,
  }) async {
    try {
      await _inventoryService.adjustStock(
        menuItemId: menuItemId,
        adjustment: adjustment,
        reason: reason,
        notes: notes,
      );
      await loadInventory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh inventory
  Future<void> refresh() async {
    await loadInventory();
  }
}

/// Providers
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return InventoryService(syncService: syncService);
});

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  final inventoryService = ref.watch(inventoryServiceProvider);
  return InventoryNotifier(inventoryService);
});
