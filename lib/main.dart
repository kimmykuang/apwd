import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/crypto_service.dart';
import 'services/password_service.dart';
import 'services/group_service.dart';
import 'services/generator_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/password_provider.dart';
import 'providers/group_provider.dart';
import 'providers/settings_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/setup_password_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/password_detail_screen.dart';
import 'screens/password_edit_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/unsupported_platform_screen.dart';

void main() {
  // Web platform is not supported due to SQLCipher incompatibility
  if (kIsWeb) {
    runApp(const UnsupportedPlatformScreen());
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final dbService = DatabaseService();
    final cryptoService = CryptoService();
    final authService = AuthService(dbService, cryptoService);
    final passwordService = PasswordService(dbService);
    final groupService = GroupService(dbService);
    final generatorService = GeneratorService();

    return MultiProvider(
      providers: [
        // Services
        Provider<DatabaseService>.value(value: dbService),
        Provider<CryptoService>.value(value: cryptoService),
        Provider<AuthService>.value(value: authService),
        Provider<PasswordService>.value(value: passwordService),
        Provider<GroupService>.value(value: groupService),
        Provider<GeneratorService>.value(value: generatorService),

        // Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => PasswordProvider(passwordService, cryptoService),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupProvider(groupService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(dbService),
        ),
      ],
      child: MaterialApp(
        title: 'APWD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
          ),
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const SplashScreen(),
              );
            case '/setup':
              return MaterialPageRoute(
                builder: (_) => const SetupPasswordScreen(),
              );
            case '/lock':
              return MaterialPageRoute(
                builder: (_) => const LockScreen(),
              );
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
            case '/password-detail':
              final passwordId = settings.arguments as int?;
              if (passwordId == null) {
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('Password ID required')),
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (_) => PasswordDetailScreen(passwordId: passwordId),
              );
            case '/password-edit':
              final passwordId = settings.arguments as int?;
              return MaterialPageRoute(
                builder: (_) => PasswordEditScreen(passwordId: passwordId),
              );
            case '/settings':
              return MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Page not found')),
                ),
              );
          }
        },
      ),
    );
  }
}
