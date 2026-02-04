import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/checkout/checkout_screen.dart';
import 'ui/screens/order_success/order_success_screen.dart';
import 'ui/screens/settings/sync_settings_screen.dart';

/// GoRouter configuration with no animations
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash Screen
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashScreen(),
      ),
    ),
    
    // Main Dashboard (5 tabs)
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: DashboardScreen(),
      ),
    ),
    
    // Checkout with payment
    GoRoute(
      path: '/checkout',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CheckoutScreen(),
      ),
    ),
    
    // Order Success
    GoRoute(
      path: '/order-success/:orderId/:total',
      pageBuilder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final total = double.tryParse(state.pathParameters['total'] ?? '0') ?? 0.0;
        return NoTransitionPage(
          child: OrderSuccessScreen(orderId: orderId, totalAmount: total),
        );
      },
    ),
    
    // Sync Settings
    GoRoute(
      path: '/settings/sync',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SyncSettingsScreen(),
      ),
    ),
  ],
);


/// Main App Widget
class CarmenGardenApp extends StatelessWidget {
  const CarmenGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CGC POS',
      debugShowCheckedModeBanner: false,
      theme: CarmenTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
