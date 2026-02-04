// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActivityLogImpl _$$ActivityLogImplFromJson(Map<String, dynamic> json) =>
    _$ActivityLogImpl(
      id: json['id'] as String,
      eventType: $enumDecode(_$ActivityEventTypeEnumMap, json['eventType']),
      entityType: $enumDecode(_$ActivityEntityTypeEnumMap, json['entityType']),
      entityId: json['entityId'] as String?,
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$ActivityLogImplToJson(_$ActivityLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventType': _$ActivityEventTypeEnumMap[instance.eventType]!,
      'entityType': _$ActivityEntityTypeEnumMap[instance.entityType]!,
      'entityId': instance.entityId,
      'description': instance.description,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'isSynced': instance.isSynced,
    };

const _$ActivityEventTypeEnumMap = {
  ActivityEventType.orderCreated: 'orderCreated',
  ActivityEventType.orderUpdated: 'orderUpdated',
  ActivityEventType.orderStatusChanged: 'orderStatusChanged',
  ActivityEventType.orderCompleted: 'orderCompleted',
  ActivityEventType.orderCancelled: 'orderCancelled',
  ActivityEventType.orderVoided: 'orderVoided',
  ActivityEventType.orderDeleted: 'orderDeleted',
  ActivityEventType.paymentProcessed: 'paymentProcessed',
  ActivityEventType.paymentRefunded: 'paymentRefunded',
  ActivityEventType.inventoryAdjusted: 'inventoryAdjusted',
  ActivityEventType.inventoryRestocked: 'inventoryRestocked',
  ActivityEventType.itemAdded: 'itemAdded',
  ActivityEventType.itemUpdated: 'itemUpdated',
  ActivityEventType.itemDeleted: 'itemDeleted',
  ActivityEventType.syncCompleted: 'syncCompleted',
  ActivityEventType.syncFailed: 'syncFailed',
  ActivityEventType.menuSynced: 'menuSynced',
  ActivityEventType.dataExported: 'dataExported',
};

const _$ActivityEntityTypeEnumMap = {
  ActivityEntityType.order: 'order',
  ActivityEntityType.orderItem: 'orderItem',
  ActivityEntityType.payment: 'payment',
  ActivityEntityType.menuItem: 'menuItem',
  ActivityEntityType.category: 'category',
  ActivityEntityType.inventory: 'inventory',
  ActivityEntityType.system: 'system',
};
