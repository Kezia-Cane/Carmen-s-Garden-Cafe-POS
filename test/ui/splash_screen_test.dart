import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:carmen_garden_pos/ui/screens/splash/splash_screen.dart';
import 'package:carmen_garden_pos/data/database_helper.dart';
import 'package:carmen_garden_pos/data/sample_data_seeder.dart';
import 'package:carmen_garden_pos/services/connectivity_service.dart';
import 'package:carmen_garden_pos/services/sync_service.dart';

import 'package:sqflite/sqflite.dart';

// Generate mocks
@GenerateMocks([
  DatabaseHelper,
  SampleDataSeeder,
  ConnectivityService,
  SyncService,
  Database, // Add this
])
import 'splash_screen_test.mocks.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockSampleDataSeeder mockSeeder;
  late MockConnectivityService mockConnectivityService;
  late MockSyncService mockSyncService;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockSeeder = MockSampleDataSeeder();
    mockConnectivityService = MockConnectivityService();
    mockSyncService = MockSyncService();

    // Default success stubs
    when(mockDbHelper.database).thenAnswer((_) async => throw UnimplementedError()); // We don't need real DB, just the future to complete
    // Actually database getter returns Future<Database>. 
    // We can just stub it to return *something* or throw if we want failure. 
    // But since `SplashScreen` awaits it: `await dbHelper.database`, we need it to complete successfully.
    // Creating a mock Database object is recursive and painful.
    // However, `SplashScreen` doesn't USE the value, just awaits calls.
    // So we can just return any Future.
    // But type safety require Future<Database>. 
    // Let's rely on Mockito's generator to give us a MockDatabase if needed, or just standard "fake".
    // Actually, simpler: `when(mockDbHelper.database).thenAnswer((_) async => MockDatabase());`
    // We need MockDatabase.
  });

  // We need to generate MockDatabase too if we use it in return type.
  // Or just use `null` if we can trace that it's not used? 
  // `await dbHelper.database` -> if it returns null, await null completes immediately.
  // But type is Future<Database>. 
  
  // Let's modify the test to simple verifying interaction.

  testWidgets('Splash screen initializes successfully', (WidgetTester tester) async {
    // Mock successful database init
    final mockDb = MockDatabase();
    when(mockDbHelper.database).thenAnswer((_) async => mockDb);

    // Mock successful seeding
    when(mockSeeder.seedAll()).thenAnswer((_) async {});

    // Mock successful service init
    when(mockConnectivityService.initialize()).thenAnswer((_) async {});
    when(mockSyncService.initialize()).thenReturn(null); // void

    // Setup GoRouter
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseHelperProvider.overrideWithValue(mockDbHelper),
          sampleDataSeederProvider.overrideWithValue(mockSeeder),
          connectivityServiceProvider.overrideWithValue(mockConnectivityService),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Carmen\'s Garden'), findsOneWidget);
    // initState calls _initializeApp which immediately sets 'Loading database...'
    expect(find.text('Loading database...'), findsOneWidget);

    // Allow async operations to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify services were called
    verify(mockDbHelper.database).called(1);
    verify(mockSeeder.seedAll()).called(1);
    verify(mockConnectivityService.initialize()).called(1);
    verify(mockSyncService.initialize()).called(1);
    
    // Verify navigation to dashboard occurred
    expect(find.text('Dashboard Screen'), findsOneWidget);
  });

  testWidgets('Splash screen shows error on failure', (WidgetTester tester) async {
    // Mock database failure
    when(mockDbHelper.database).thenThrow('DB Error');
    
    // Simple mock router for error case
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseHelperProvider.overrideWithValue(mockDbHelper),
          sampleDataSeederProvider.overrideWithValue(mockSeeder),
          connectivityServiceProvider.overrideWithValue(mockConnectivityService),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error: DB Error'), findsOneWidget);
  });
}
