import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:uuid/uuid.dart';
import 'package:carmen_garden_pos/services/order_service.dart';
import 'package:carmen_garden_pos/data/datasources/local/order_dao.dart';
import 'package:carmen_garden_pos/data/database_helper.dart';
import 'package:carmen_garden_pos/services/cart_service.dart';
import 'package:carmen_garden_pos/models/order.dart';
import 'package:carmen_garden_pos/models/menu_item.dart';
// CartItem is exported from cart_service.dart

// Generate mocks
@GenerateMocks([OrderDao, DatabaseHelper, Uuid])
import 'order_service_test.mocks.dart';

void main() {
  late OrderService orderService;
  late MockOrderDao mockOrderDao;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockUuid mockUuid;

  setUp(() {
    mockOrderDao = MockOrderDao();
    mockDatabaseHelper = MockDatabaseHelper();
    mockUuid = MockUuid();
    orderService = OrderService(
      orderDao: mockOrderDao,
      dbHelper: mockDatabaseHelper,
      uuid: mockUuid,
    );
  });

  group('OrderService Tests', () {
    test('createOrder throws exception with empty cart', () async {
      final emptyCart = CartState(items: []);
      
      expect(
        () => orderService.createOrder(cart: emptyCart),
        throwsException,
      );
    });

    test('updateOrderStatus calls dao update', () async {
      const orderId = 'test-id';
      const newStatus = OrderStatus.preparing;
      
      // Setup mock behavior
      when(mockOrderDao.updateOrderStatus(orderId, newStatus))
          .thenAnswer((_) async {});
          
      // Act
      await orderService.updateOrderStatus(orderId, newStatus);
      
      // Verify
      verify(mockOrderDao.updateOrderStatus(orderId, newStatus)).called(1);
    });
    
    // Add more tests here as needed
  });
}
