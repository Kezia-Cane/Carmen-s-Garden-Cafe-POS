import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_log.freezed.dart';
part 'activity_log.g.dart';

/// Activity event type enum (16 types as per spec)
enum ActivityEventType {
  orderCreated,
  orderUpdated,
  orderStatusChanged,
  orderCompleted,
  orderCancelled,
  orderVoided,
  orderDeleted,
  paymentProcessed,
  paymentRefunded,
  inventoryAdjusted,
  inventoryRestocked,
  itemAdded,
  itemUpdated,
  itemDeleted,
  syncCompleted,
  syncFailed,
  menuSynced,
  dataExported,
}

/// Entity type for activity logs
enum ActivityEntityType {
  order,
  orderItem,
  payment,
  menuItem,
  category,
  inventory,
  system,
}

/// Activity log model
@freezed
class ActivityLog with _$ActivityLog {
  const factory ActivityLog({
    required String id,
    required ActivityEventType eventType,
    required ActivityEntityType entityType,
    String? entityId,
    required String description,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    @Default(false) bool isSynced,
  }) = _ActivityLog;

  factory ActivityLog.fromJson(Map<String, dynamic> json) => _$ActivityLogFromJson(json);
}
