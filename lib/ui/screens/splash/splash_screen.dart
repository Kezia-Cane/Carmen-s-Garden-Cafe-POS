import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/color_palette.dart';
import '../../../data/database_helper.dart';
import '../../../data/sample_data_seeder.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/sync_service.dart';

/// Splash Screen - App entry point
/// Shows logo while initializing database and services
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusMessage = 'Starting...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize database
      setState(() => _statusMessage = 'Loading database...');
      final dbHelper = ref.read(databaseHelperProvider);
      await dbHelper.database;
      
      // Step 2: Seed sample data if empty
      setState(() => _statusMessage = 'Setting up menu...');
      final seeder = ref.read(sampleDataSeederProvider);
      await seeder.seedAll();
      
      // Step 3: Initialize connectivity and sync services
      setState(() => _statusMessage = 'Starting services...');
      final connectivityService = ref.read(connectivityServiceProvider);
      await connectivityService.initialize();
      
      final syncService = ref.read(syncServiceProvider);
      syncService.initialize();
      
      // Step 4: Small delay for UI
      setState(() => _statusMessage = 'Ready!');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Navigate to dashboard
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CarmenColors.primaryGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/carmenlogo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.local_cafe,
                      size: 80,
                      color: CarmenColors.primaryGreen,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              const Text(
                "Carmen's Garden",
                style: TextStyle(
                  fontFamily: 'Epilogue',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Cafe & Food Dining',
                style: TextStyle(
                  fontFamily: 'Epilogue',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Status message (no animated spinner for performance)
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontFamily: 'Epilogue',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
