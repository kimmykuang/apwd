import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Splash screen that checks initialization status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final dbService = context.read<DatabaseService>();
      final authProvider = context.read<AuthProvider>();

      // Get database path
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(appDir.path, AppConstants.dbName);

      // Check if database file exists (indicates setup was completed)
      final dbFile = File(dbPath);
      final isInitialized = await dbFile.exists();

      if (!mounted) return;

      if (isInitialized) {
        Navigator.of(context).pushReplacementNamed('/lock');
      } else {
        Navigator.of(context).pushReplacementNamed('/setup');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              'APWD',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Secure Password Manager',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
