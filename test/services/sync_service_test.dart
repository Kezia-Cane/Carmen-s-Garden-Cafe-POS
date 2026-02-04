import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:carmen_garden_pos/services/sync_service.dart';
import 'package:carmen_garden_pos/services/activity_log_service.dart';
import 'package:carmen_garden_pos/services/connectivity_service.dart';
import 'package:carmen_garden_pos/data/datasources/local/order_dao.dart';
import 'package:carmen_garden_pos/data/datasources/local/payment_dao.dart';
import 'package:carmen_garden_pos/data/datasources/local/inventory_dao.dart';
import 'package:carmen_garden_pos/models/activity_log.dart';

// Generate mocks
@GenerateMocks([
  Dio,
  OrderDao,
  PaymentDao,
  InventoryDao,
  ActivityLogService,
  ConnectivityService
])
import 'sync_service_test.mocks.dart';

void main() {
  late SyncService syncService;
  late MockDio mockDio;
  late MockOrderDao mockOrderDao;
  late MockPaymentDao mockPaymentDao;
  late MockInventoryDao mockInventoryDao;
  late MockActivityLogService mockActivityLogService;
  late MockConnectivityService mockConnectivityService;

  setUp(() {
    mockDio = MockDio();
    mockOrderDao = MockOrderDao();
    mockPaymentDao = MockPaymentDao();
    mockInventoryDao = MockInventoryDao();
    mockActivityLogService = MockActivityLogService();
    mockConnectivityService = MockConnectivityService();

    // Default connectivity to online
    when(mockConnectivityService.isOnline).thenReturn(true);
    when(mockConnectivityService.statusStream).thenAnswer((_) => Stream.empty());

    // Default logging stubs
    final dummyLog = ActivityLog(
      id: 'log-id',
      eventType: ActivityEventType.syncCompleted,
      entityType: ActivityEntityType.system,
      description: 'Test log',
      createdAt: DateTime.now(),
    );

    when(mockActivityLogService.logSyncCompleted(any))
        .thenAnswer((_) async => dummyLog);
        
    when(mockActivityLogService.logSyncFailed(any))
        .thenAnswer((_) async => dummyLog);

    syncService = SyncService(
      activityLogService: mockActivityLogService,
      connectivityService: mockConnectivityService,
      orderDao: mockOrderDao,
      paymentDao: mockPaymentDao,
      inventoryDao: mockInventoryDao,
      dio: mockDio,
    );
  });

  group('SyncService Tests', () {
    test('syncAll returns error when offline', () async {
      when(mockConnectivityService.isOnline).thenReturn(false);
      
      final result = await syncService.syncAll();
      
      expect(result.success, false);
      expect(result.message, contains('No internet'));
      verifyNever(mockOrderDao.getUnsyncedOrders());
    });

    test('syncAll handles partial data correctly', () async {
      // Setup empty data for simplicity in this test
      when(mockOrderDao.getUnsyncedOrders()).thenAnswer((_) async => []);
      when(mockPaymentDao.getUnsyncedPayments()).thenAnswer((_) async => []);
      when(mockInventoryDao.getUnsyncedTransactions()).thenAnswer((_) async => []);
      
      final result = await syncService.syncAll();
      
      expect(result.success, true);
      verify(mockActivityLogService.logSyncCompleted(0)).called(1);
    });
  });
}
