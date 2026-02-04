import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/sync_service.dart';
import '../../../config/color_palette.dart';

class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final syncNotifier = ref.read(syncProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Synchronization'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Row(
                    children: [
                      Icon(
                        _getStatusIcon(syncState.status),
                        color: _getStatusColor(syncState.status),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${_getStatusText(syncState.status)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Pending Items: ${syncState.pendingCount}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (syncState.lastError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Error: ${syncState.lastError}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  if (syncState.lastSyncTime != null) ...[
                     const SizedBox(height: 8),
                     Text(
                      'Last Synced: ${_formatDate(syncState.lastSyncTime!)}',
                       style: TextStyle(color: Colors.grey[500], fontSize: 12),
                     ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Sync All Button
            _ActionButton(
              icon: Icons.sync,
              label: 'Sync All Data',
              description: 'Sync with cloud (Push & Pull)',
              color: CarmenColors.primaryGreen,
              onTap: syncState.status == SyncStatus.syncing 
                  ? null 
                  : () => syncNotifier.syncAndRestore(),
            ),
            
            const SizedBox(height: 16),

            // Restore Button
            _ActionButton(
              icon: Icons.cloud_download,
              label: 'Restore Data (Pull)',
              description: 'Download orders from cloud. existing data will be updated.',
              color: Colors.blueAccent,
              onTap: syncState.status == SyncStatus.syncing 
                  ? null 
                  : () => _confirmRestore(context, syncNotifier),
            ),
            
            const Spacer(),
            const Center(
               child: Text(
                 'Note: Valid Internet connection required.',
                 style: TextStyle(color: Colors.grey),
               ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmRestore(BuildContext context, SyncNotifier notifier) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text('This will download past orders from the cloud. \n\nOnly orders will be restored currently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.restore();
            },
            child: const Text('Restore'),
          ),
        ],
      )
    );
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.success: return Icons.check_circle;
      case SyncStatus.error: return Icons.error;
      case SyncStatus.syncing: return Icons.sync;
      case SyncStatus.idle: return Icons.cloud_done;
    }
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.success: return Colors.green;
      case SyncStatus.error: return Colors.red;
      case SyncStatus.syncing: return Colors.blue;
      case SyncStatus.idle: return Colors.grey;
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.success: return 'Synced';
      case SyncStatus.error: return 'Error';
      case SyncStatus.syncing: return 'Syncing...';
      case SyncStatus.idle: return 'Idle';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}/${date.year}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap == null)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
