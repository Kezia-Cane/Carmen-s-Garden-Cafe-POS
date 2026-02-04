import '../../database_helper.dart';
import '../../../models/inventory.dart';

/// Inventory Data Access Object
/// Handles stock management and transactions
class InventoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============ INVENTORY ============

  // Get or create inventory for a menu item
  Future<Inventory> getOrCreateInventory(String menuItemId) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'inventory',
      where: 'menu_item_id = ?',
      whereArgs: [menuItemId],
    );

    if (maps.isNotEmpty) {
      return _mapToInventory(maps.first);
    }

    // Create new inventory record
    final now = DateTime.now();
    final id = 'inv_${now.millisecondsSinceEpoch}';
    
    await db.insert('inventory', {
      'id': id,
      'menu_item_id': menuItemId,
      'current_stock': 0,
      'low_stock_threshold': 10,
      'updated_at': now.toIso8601String(),
    });

    return Inventory(
      id: id,
      menuItemId: menuItemId,
      currentStock: 0,
      lowStockThreshold: 10,
      updatedAt: now,
    );
  }

  // Get all inventory items
  Future<List<Inventory>> getAllInventory() async {
    final db = await _dbHelper.database;
    final maps = await db.query('inventory');
    return maps.map(_mapToInventory).toList();
  }

  // Get low stock items
  Future<List<Inventory>> getLowStockItems() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      'SELECT * FROM inventory WHERE current_stock <= low_stock_threshold',
    );
    return maps.map(_mapToInventory).toList();
  }

  // Update stock level
  Future<Inventory> updateStock({
    required String menuItemId,
    required int newStock,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    
    await db.update(
      'inventory',
      {
        'current_stock': newStock,
        'updated_at': now.toIso8601String(),
      },
      where: 'menu_item_id = ?',
      whereArgs: [menuItemId],
    );

    return (await getOrCreateInventory(menuItemId));
  }

  // Adjust stock (increment/decrement)
  Future<Inventory> adjustStock({
    required String menuItemId,
    required int adjustment,
    required InventoryAdjustmentReason reason,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    
    // Get current inventory
    final inventory = await getOrCreateInventory(menuItemId);
    final newStock = inventory.currentStock + adjustment;
    
    // Update stock
    await db.update(
      'inventory',
      {
        'current_stock': newStock < 0 ? 0 : newStock,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [inventory.id],
    );

    // Log transaction
    await createTransaction(InventoryTransaction(
      id: 'invt_${now.millisecondsSinceEpoch}',
      inventoryId: inventory.id,
      quantityChange: adjustment,
      reason: reason,
      notes: notes,
      createdAt: now,
    ));

    return inventory.copyWith(
      currentStock: newStock < 0 ? 0 : newStock,
      updatedAt: now,
    );
  }

  // ============ TRANSACTIONS ============

  // Create inventory transaction
  Future<InventoryTransaction> createTransaction(InventoryTransaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert('inventory_transactions', {
      'id': transaction.id,
      'inventory_id': transaction.inventoryId,
      'quantity_change': transaction.quantityChange,
      'reason': transaction.reason.name,
      'notes': transaction.notes,
      'created_at': transaction.createdAt.toIso8601String(),
      'is_synced': transaction.isSynced ? 1 : 0,
    });
    return transaction;
  }

  // Get transactions for an inventory item
  Future<List<InventoryTransaction>> getTransactions({
    required String inventoryId,
    int limit = 50,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'inventory_transactions',
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map(_mapToTransaction).toList();
  }

  // Get unsynced transactions
  Future<List<InventoryTransaction>> getUnsyncedTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'inventory_transactions',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );
    return maps.map(_mapToTransaction).toList();
  }

  // Mark transaction as synced
  Future<void> markTransactionAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'inventory_transactions',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper: Map to Inventory
  Inventory _mapToInventory(Map<String, dynamic> map) {
    return Inventory(
      id: map['id'] as String,
      menuItemId: map['menu_item_id'] as String,
      currentStock: map['current_stock'] as int,
      lowStockThreshold: map['low_stock_threshold'] as int,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Helper: Map to InventoryTransaction
  InventoryTransaction _mapToTransaction(Map<String, dynamic> map) {
    return InventoryTransaction(
      id: map['id'] as String,
      inventoryId: map['inventory_id'] as String,
      quantityChange: map['quantity_change'] as int,
      reason: InventoryAdjustmentReason.values.firstWhere(
        (r) => r.name == map['reason'],
        orElse: () => InventoryAdjustmentReason.countCorrection,
      ),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}
