import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';

/// SQLite Database Helper
/// Manages local database for offline-first operation
/// Optimized for OUKITEL WP18 with indexed queries
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Menu items table
    await db.execute('''
      CREATE TABLE menu_items (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        image_url TEXT,
        is_available INTEGER DEFAULT 1,
        track_inventory INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_menu_items_category ON menu_items(category_id)');
    await db.execute('CREATE INDEX idx_menu_items_available ON menu_items(is_available)');

    // Item modifiers table (Size, Milk, Sugar, etc.)
    await db.execute('''
      CREATE TABLE item_modifiers (
        id TEXT PRIMARY KEY,
        menu_item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        options TEXT NOT NULL,
        is_required INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (menu_item_id) REFERENCES menu_items (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_modifiers_item ON item_modifiers(menu_item_id)');

    // Orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number INTEGER NOT NULL,
        customer_name TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        subtotal REAL NOT NULL,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
    await db.execute('CREATE INDEX idx_orders_created ON orders(created_at)');
    await db.execute('CREATE INDEX idx_orders_synced ON orders(is_synced)');

    // Order items table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        menu_item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        modifiers TEXT,
        special_instructions TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (menu_item_id) REFERENCES menu_items (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_order_items_order ON order_items(order_id)');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        amount_tendered REAL NOT NULL,
        change_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_payments_order ON payments(order_id)');
    await db.execute('CREATE INDEX idx_payments_created ON payments(created_at)');

    // Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        menu_item_id TEXT NOT NULL UNIQUE,
        current_stock INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER DEFAULT 10,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (menu_item_id) REFERENCES menu_items (id)
      )
    ''');

    // Inventory transactions table
    await db.execute('''
      CREATE TABLE inventory_transactions (
        id TEXT PRIMARY KEY,
        inventory_id TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (inventory_id) REFERENCES inventory (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_inv_trans_inventory ON inventory_transactions(inventory_id)');

    // Activity logs table
    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        description TEXT NOT NULL,
        metadata TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_activity_event ON activity_logs(event_type)');
    await db.execute('CREATE INDEX idx_activity_entity ON activity_logs(entity_type)');
    await db.execute('CREATE INDEX idx_activity_created ON activity_logs(created_at)');

    // Sync queue table (for offline operations)
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        operation TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)');

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default settings
    final now = DateTime.now().toIso8601String();
    await db.insert('app_settings', {
      'key': 'tax_rate',
      'value': '0.08',
      'updated_at': now,
    });
    await db.insert('app_settings', {
      'key': 'currency_symbol',
      'value': '₱',
      'updated_at': now,
    });
    await db.insert('app_settings', {
      'key': 'last_order_number',
      'value': '0',
      'updated_at': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // For now, we start with version 1
  }

  // Helper method to get next order number
  Future<int> getNextOrderNumber() async {
    final db = await database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['last_order_number'],
    );
    
    int lastNumber = 0;
    if (result.isNotEmpty) {
      lastNumber = int.tryParse(result.first['value'] as String) ?? 0;
    }
    
    final nextNumber = lastNumber + 1;
    await db.update(
      'app_settings',
      {
        'value': nextNumber.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: ['last_order_number'],
    );
    
    return nextNumber;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sync_queue');
    await db.delete('activity_logs');
    await db.delete('inventory_transactions');
    await db.delete('inventory');
    await db.delete('payments');
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('item_modifiers');
    await db.delete('menu_items');
    await db.delete('categories');
  }
}

/// Provider for DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});
