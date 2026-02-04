import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/color_palette.dart';
import '../../../services/activity_log_service.dart';
import '../../../models/activity_log.dart';

/// Activity Screen - View activity logs
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityLogProvider.notifier).loadTodaysLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        backgroundColor: CarmenColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings/sync'),
            icon: const Icon(Icons.cloud_sync),
          ),
          IconButton(
            onPressed: () => ref.read(activityLogProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: activityState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activityState.logs.isEmpty
              ? _buildEmptyState()
              : _buildActivityList(activityState),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No activity today',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(ActivityLogState activityState) {
    // Group logs by hour
    final groupedLogs = <String, List<ActivityLog>>{};
    for (final log in activityState.logs) {
      final hour = '${log.createdAt.hour}:00';
      groupedLogs.putIfAbsent(hour, () => []);
      groupedLogs[hour]!.add(log);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(activityLogProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: activityState.logs.length,
        itemBuilder: (context, index) {
          final log = activityState.logs[index];
          return _buildActivityCard(log);
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getEventColor(log.eventType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getEventIcon(log.eventType),
                color: _getEventColor(log.eventType),
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Description and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getEventColor(log.eventType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getEventLabel(log.eventType),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getEventColor(log.eventType),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(log.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(ActivityEventType eventType) {
    switch (eventType) {
      case ActivityEventType.orderCreated:
        return Icons.add_shopping_cart;
      case ActivityEventType.orderUpdated:
      case ActivityEventType.orderStatusChanged:
        return Icons.update;
      case ActivityEventType.orderCompleted:
        return Icons.check_circle;
      case ActivityEventType.orderCancelled:
      case ActivityEventType.orderVoided:
      case ActivityEventType.orderDeleted:
        return Icons.cancel;
      case ActivityEventType.paymentProcessed:
        return Icons.payment;
      case ActivityEventType.paymentRefunded:
        return Icons.money_off;
      case ActivityEventType.inventoryAdjusted:
      case ActivityEventType.inventoryRestocked:
        return Icons.inventory;
      case ActivityEventType.itemAdded:
      case ActivityEventType.itemUpdated:
      case ActivityEventType.itemDeleted:
        return Icons.fastfood;
      case ActivityEventType.syncCompleted:
        return Icons.cloud_done;
      case ActivityEventType.syncFailed:
        return Icons.cloud_off;
      case ActivityEventType.menuSynced:
        return Icons.menu_book;
      case ActivityEventType.dataExported:
        return Icons.download;
    }
  }

  Color _getEventColor(ActivityEventType eventType) {
    switch (eventType) {
      case ActivityEventType.orderCreated:
        return Colors.blue;
      case ActivityEventType.orderCompleted:
      case ActivityEventType.syncCompleted:
        return CarmenColors.successGreen;
      case ActivityEventType.orderCancelled:
      case ActivityEventType.orderVoided:
      case ActivityEventType.orderDeleted:
      case ActivityEventType.syncFailed:
        return Colors.red;
      case ActivityEventType.paymentProcessed:
        return CarmenColors.primaryGreen;
      case ActivityEventType.inventoryAdjusted:
      case ActivityEventType.inventoryRestocked:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEventLabel(ActivityEventType eventType) {
    switch (eventType) {
      case ActivityEventType.orderCreated:
        return 'Order';
      case ActivityEventType.orderUpdated:
      case ActivityEventType.orderStatusChanged:
        return 'Update';
      case ActivityEventType.orderCompleted:
        return 'Complete';
      case ActivityEventType.orderCancelled:
      case ActivityEventType.orderVoided:
      case ActivityEventType.orderDeleted:
        return 'Cancel';
      case ActivityEventType.paymentProcessed:
        return 'Payment';
      case ActivityEventType.paymentRefunded:
        return 'Refund';
      case ActivityEventType.inventoryAdjusted:
      case ActivityEventType.inventoryRestocked:
        return 'Inventory';
      case ActivityEventType.itemAdded:
      case ActivityEventType.itemUpdated:
      case ActivityEventType.itemDeleted:
        return 'Menu';
      case ActivityEventType.syncCompleted:
      case ActivityEventType.syncFailed:
        return 'Sync';
      case ActivityEventType.menuSynced:
        return 'Menu Sync';
      case ActivityEventType.dataExported:
        return 'Export';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
