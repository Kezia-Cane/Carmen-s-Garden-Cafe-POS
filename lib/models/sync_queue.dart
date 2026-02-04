import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue.freezed.dart';
part 'sync_queue.g.dart';

/// Sync operation type
enum SyncOperation {
  create,
  update,
  delete,
}

/// Sync queue item model
@freezed
class SyncQueueItem with _$SyncQueueItem {
  const factory SyncQueueItem({
    required String id,
    required SyncOperation operation,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
    @Default(0) int retryCount,
    String? lastError,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SyncQueueItem;

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => _$SyncQueueItemFromJson(json);
}
