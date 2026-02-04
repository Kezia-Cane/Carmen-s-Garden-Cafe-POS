import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:carmen_garden_pos/services/connectivity_service.dart';
import 'dart:async';

// Generate mocks for Connectivity
@GenerateMocks([Connectivity])
import 'connectivity_service_test.mocks.dart';

void main() {
  late ConnectivityService connectivityService;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityService = ConnectivityService(connectivity: mockConnectivity);
  });

  group('ConnectivityService Tests', () {
    test('initialization checks status', () async {
      // Setup
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.value(ConnectivityResult.wifi));

      // Act
      await connectivityService.initialize();

      // Verify
      verify(mockConnectivity.checkConnectivity()).called(1);
      expect(connectivityService.isOnline, true);
    });

    test('updates status on stream change', () async {
      // Setup
      final controller = StreamController<ConnectivityResult>();
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);

      // Act
      await connectivityService.initialize();
      expect(connectivityService.isOnline, false);

      // Emulate change
      controller.add(ConnectivityResult.mobile);
      await Future.delayed(Duration.zero); // Process stream

      // Verify
      expect(connectivityService.isOnline, true);
      
      await controller.close();
    });
  });
}
