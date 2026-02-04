import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local/order_dao.dart';
import '../data/datasources/local/payment_dao.dart';
import '../data/datasources/local/activity_log_dao.dart';
import '../models/order.dart';

/// Report data for a specific period
class PeriodReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final int orderCount;
  final int completedOrders;
  final int cancelledOrders;
  final Map<OrderStatus, int> ordersByStatus;
  final double averageOrderValue;

  const PeriodReport({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.orderCount,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.ordersByStatus,
    required this.averageOrderValue,
  });
}

/// Top selling item data
class TopSellingItem {
  final String name;
  final int quantity;
  final double revenue;

  const TopSellingItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

/// Sync status data
class SyncStats {
  final int totalLogs;
  final int syncedLogs;
  final int unsyncedLogs;
  final double syncPercentage;

  const SyncStats({
    required this.totalLogs,
    required this.syncedLogs,
    required this.unsyncedLogs,
    required this.syncPercentage,
  });
}

/// Reports service for analytics
class ReportsService {
  final OrderDao _orderDao = OrderDao();
  final PaymentDao _paymentDao = PaymentDao();
  final ActivityLogDao _activityLogDao = ActivityLogDao();

  /// Get report for a specific period
  Future<PeriodReport> getPeriodReport(DateTime start, DateTime end) async {
    // Get orders
    final orders = await _orderDao.getOrders(
      fromDate: start,
      toDate: end,
      limit: 10000, // Increase limit for aggregation
    );

    // Get payments (total sales)
    final totalSales = await _paymentDao.getTotalSales(
      fromDate: start,
      toDate: end,
    );

    // Calculate stats
    final ordersByStatus = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      ordersByStatus[status] = orders.where((o) => o.status == status).length;
    }

    final completedOrders = ordersByStatus[OrderStatus.completed] ?? 0;
    // Map 'voided' to 'cancelled' for reporting purposes if needed, OR just count voided
    // Assuming OrderStatus also has 'voided' now? 
    // If OrderStatus has voided, we should count it. The user wants "Canceled" changed to "Void" in UI.
    // So distinct counts for each.
    final cancelledOrders = (ordersByStatus[OrderStatus.cancelled] ?? 0) + (ordersByStatus[OrderStatus.voided] ?? 0);
    
    final averageOrderValue = completedOrders > 0 ? totalSales / completedOrders : 0.0;

    return PeriodReport(
      startDate: start,
      endDate: end,
      totalSales: totalSales,
      orderCount: orders.length,
      completedOrders: completedOrders,
      cancelledOrders: cancelledOrders,
      ordersByStatus: ordersByStatus,
      averageOrderValue: averageOrderValue,
    );
  }

  /// Get daily report (Today)
  Future<PeriodReport> getDailyReport({DateTime? date}) async {
    date ??= DateTime.now();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getPeriodReport(startOfDay, endOfDay);
  }

  /// Get weekly sales totals
  Future<Map<DateTime, double>> getWeeklySales() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final result = <DateTime, double>{};

    for (int i = 0; i < 7; i++) {
      final day = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);
      final nextDay = day.add(const Duration(days: 1));
      
      final sales = await _paymentDao.getTotalSales(
        fromDate: day,
        toDate: nextDay,
      );
      result[day] = sales;
    }

    return result;
  }

  /// Get monthly sales totals
  Future<Map<DateTime, double>> getMonthlySales() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final result = <DateTime, double>{};

    for (int i = 0; i < 31; i++) {
      final day = DateTime(startOfMonth.year, startOfMonth.month, startOfMonth.day + i);
      if (day.isAfter(now)) break;
      
      final nextDay = day.add(const Duration(days: 1));
      
      final sales = await _paymentDao.getTotalSales(
        fromDate: day,
        toDate: nextDay,
      );
      result[day] = sales;
    }

    return result;
  }

  /// Get top selling items
  Future<List<TopSellingItem>> getTopSellingItems({int limit = 5, DateTime? fromDate, DateTime? toDate}) async {
    fromDate ??= DateTime.now().subtract(const Duration(days: 7));
    toDate ??= DateTime.now();
    
    final orders = await _orderDao.getOrders(
      fromDate: fromDate,
      toDate: toDate,
      status: OrderStatus.completed,
      limit: 1000,
    );

    // Aggregate items
    final itemStats = <String, Map<String, dynamic>>{};
    for (final order in orders) {
      for (final item in order.items) {
        if (!itemStats.containsKey(item.name)) {
          itemStats[item.name] = {'quantity': 0, 'revenue': 0.0};
        }
        itemStats[item.name]!['quantity'] += item.quantity;
        itemStats[item.name]!['revenue'] += item.totalPrice;
      }
    }

    // Sort by quantity and take top N
    final sorted = itemStats.entries.toList()
      ..sort((a, b) => (b.value['quantity'] as int).compareTo(a.value['quantity'] as int));

    return sorted.take(limit).map((e) => TopSellingItem(
      name: e.key,
      quantity: e.value['quantity'] as int,
      revenue: e.value['revenue'] as double,
    )).toList();
  }

  /// Get sync status
  Future<SyncStats> getSyncStatus() async {
    final unsyncedLogs = await _activityLogDao.getUnsyncedLogs();
    final allLogs = await _activityLogDao.getLogs(limit: 1000);
    
    final total = allLogs.length;
    final unsynced = unsyncedLogs.length;
    final synced = total - unsynced;
    final percentage = total > 0 ? (synced / total) * 100 : 100.0;

    return SyncStats(
      totalLogs: total,
      syncedLogs: synced,
      unsyncedLogs: unsynced,
      syncPercentage: percentage,
    );
  }

  /// Get today's quick stats
  Future<Map<String, dynamic>> getStats(DateTime start, DateTime end) async {
    final report = await getPeriodReport(start, end);
    
    return {
      'total_sales': report.totalSales,
      'order_count': report.orderCount,
      'completed_orders': report.completedOrders,
      'average_order_value': report.averageOrderValue,
    };
  }
}

/// Reports state for UI
class ReportsState {
  final PeriodReport? dailyReport;
  final Map<DateTime, double>? weeklySales;
  final Map<DateTime, double>? monthlySales;
  final Map<String, dynamic>? quickStats; // Current displayed stats
  final Map<String, dynamic>? dailyStats;
  final Map<String, dynamic>? weeklyStats;
  final Map<String, dynamic>? monthlyStats;
  final List<TopSellingItem>? topSellingItems;
  final SyncStats? syncStatus;
  final bool isLoading;
  final String? error;
  // Date range selection for filtering
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  // Custom date range sales data
  final Map<DateTime, double>? customRangeSales;

  const ReportsState({
    this.dailyReport,
    this.weeklySales,
    this.monthlySales,
    this.quickStats,
    this.dailyStats,
    this.weeklyStats,
    this.monthlyStats,
    this.topSellingItems,
    this.syncStatus,
    this.isLoading = false,
    this.error,
    this.selectedStartDate,
    this.selectedEndDate,
    this.customRangeSales,
  });

  ReportsState copyWith({
    PeriodReport? dailyReport,
    Map<DateTime, double>? weeklySales,
    Map<DateTime, double>? monthlySales,
    Map<String, dynamic>? quickStats,
    Map<String, dynamic>? dailyStats,
    Map<String, dynamic>? weeklyStats,
    Map<String, dynamic>? monthlyStats,
    List<TopSellingItem>? topSellingItems,
    SyncStats? syncStatus,
    bool? isLoading,
    String? error,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    Map<DateTime, double>? customRangeSales,
    bool clearDateRange = false,
  }) {
    return ReportsState(
      dailyReport: dailyReport ?? this.dailyReport,
      weeklySales: weeklySales ?? this.weeklySales,
      monthlySales: monthlySales ?? this.monthlySales,
      quickStats: quickStats ?? this.quickStats,
      dailyStats: dailyStats ?? this.dailyStats,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      topSellingItems: topSellingItems ?? this.topSellingItems,
      syncStatus: syncStatus ?? this.syncStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStartDate: clearDateRange ? null : (selectedStartDate ?? this.selectedStartDate),
      selectedEndDate: clearDateRange ? null : (selectedEndDate ?? this.selectedEndDate),
      customRangeSales: customRangeSales ?? this.customRangeSales,
    );
  }
}

/// Reports notifier for UI
class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsService _reportsService;

  ReportsNotifier(this._reportsService) : super(const ReportsState());

  /// Load all reports
  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dailyReport = await _reportsService.getDailyReport();
      final weeklySales = await _reportsService.getWeeklySales();
      final monthlySales = await _reportsService.getMonthlySales();

      final topSellingItems = await _reportsService.getTopSellingItems();
      final syncStatus = await _reportsService.getSyncStatus();
      
      // Calculate period stats
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      final dailyStats = await _reportsService.getStats(todayStart, now.add(const Duration(days: 1)));
      final weeklyStats = await _reportsService.getStats(weekStart, now.add(const Duration(days: 1)));
      final monthlyStats = await _reportsService.getStats(monthStart, now.add(const Duration(days: 1)));

      state = state.copyWith(
        dailyReport: dailyReport,
        weeklySales: weeklySales,
        monthlySales: monthlySales,
        quickStats: dailyStats, // Default to daily
        dailyStats: dailyStats,
        weeklyStats: weeklyStats,
        monthlyStats: monthlyStats,
        topSellingItems: topSellingItems,
        syncStatus: syncStatus,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select tab and update stats
  void selectTab(int index) {
    Map<String, dynamic>? stats;
    switch (index) {
      case 0:
        stats = state.dailyStats;
        break;
      case 1:
        stats = state.weeklyStats;
        break;
      case 2:
        stats = state.monthlyStats;
        break;
      default:
        stats = state.dailyStats;
    }
    state = state.copyWith(quickStats: stats);
  }

  /// Load quick stats only (for dashboard)
  Future<void> loadQuickStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final dailyStats = await _reportsService.getStats(todayStart, now.add(const Duration(days: 1)));
      state = state.copyWith(quickStats: dailyStats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh reports
  Future<void> refresh() async {
    await loadReports(); // Reloads all
  }

  /// Load reports for a specific date range
  Future<void> loadReportsForDateRange(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(
      isLoading: true, 
      error: null,
      selectedStartDate: startDate,
      selectedEndDate: endDate,
    );
    try {
      // Calculate sales for each day in the range
      final customRangeSales = <DateTime, double>{};
      DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      while (!current.isAfter(end)) {
        final nextDay = current.add(const Duration(days: 1));
        final sales = await _reportsService._paymentDao.getTotalSales(
          fromDate: current,
          toDate: nextDay,
        );
        customRangeSales[current] = sales;
        current = nextDay;
      }

      // Get top selling items for the date range
      final topSellingItems = await _reportsService.getTopSellingItems(
        fromDate: startDate,
        toDate: endDate.add(const Duration(days: 1)),
      );

      // Calculate quick stats for the range
      final totalSales = customRangeSales.values.fold(0.0, (a, b) => a + b);
      final orderCount = (await _reportsService._orderDao.getOrders(
        fromDate: startDate,
        toDate: endDate.add(const Duration(days: 1)),
        limit: 1000,
      )).length;

      state = state.copyWith(
        customRangeSales: customRangeSales,
        topSellingItems: topSellingItems,
        quickStats: {
          'total_sales': totalSales,
          'order_count': orderCount,
          'average_order_value': orderCount > 0 ? totalSales / orderCount : 0.0,
        },
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear date range selection and load default reports
  Future<void> clearDateRange() async {
    state = state.copyWith(clearDateRange: true, customRangeSales: null);
    await loadReports();
  }
}

/// Providers
final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService();
});

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final reportsService = ref.watch(reportsServiceProvider);
  return ReportsNotifier(reportsService);
});

