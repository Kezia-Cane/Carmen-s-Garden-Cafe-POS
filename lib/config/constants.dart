/// App-wide constants for Carmen's Garden Cafe POS
/// All values optimized for OUKITEL WP18 performance
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = "Carmen's Garden Cafe";
  static const String appVersion = '1.0.0';
  
  // Tax Configuration
  static const double taxRate = 0.08; // 8% tax
  
  // Currency
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';
  
  // Performance Limits (OUKITEL WP18 optimized)
  static const int maxItemsPerPage = 50;
  static const int imageCacheMaxMB = 30;
  static const int maxSyncBatchSize = 20;
  static const int syncDebounceSeconds = 5;
  
  // Database
  static const String databaseName = 'carmen_garden_pos.db';
  static const int databaseVersion = 1;
  
  // Activity Log
  static const int activityLogRetentionDays = 30;
  
  // Order Number Format
  static const String orderNumberPrefix = '#';
  
  // Quick Cash Amounts (in PHP)
  static const List<double> quickCashAmounts = [50, 100, 200, 500, 1000];
  
  // Order Statuses
  static const String statusPending = 'pending';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Activity Log Event Types
  static const String eventOrderCreated = 'order_created';
  static const String eventOrderUpdated = 'order_updated';
  static const String eventOrderStatusChanged = 'order_status_changed';
  static const String eventOrderCompleted = 'order_completed';
  static const String eventOrderCancelled = 'order_cancelled';
  static const String eventOrderDeleted = 'order_deleted';
  static const String eventPaymentProcessed = 'payment_processed';
  static const String eventPaymentRefunded = 'payment_refunded';
  static const String eventInventoryAdjusted = 'inventory_adjusted';
  static const String eventInventoryRestocked = 'inventory_restocked';
  static const String eventItemAdded = 'item_added';
  static const String eventItemUpdated = 'item_updated';
  static const String eventItemDeleted = 'item_deleted';
  static const String eventSyncCompleted = 'sync_completed';
  static const String eventSyncFailed = 'sync_failed';
  static const String eventMenuSynced = 'menu_synced';
  static const String eventDataExported = 'data_exported';
}
