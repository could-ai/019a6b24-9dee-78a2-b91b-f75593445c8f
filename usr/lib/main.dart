import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/splash_screen.dart';
import 'screens/identity_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/stealth_mode_screen.dart';
import 'providers/identity_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/stealth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local encrypted storage
  await Hive.initFlutter();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IdentityProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StealthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StealthProvider>(
      builder: (context, stealthProvider, child) {
        return MaterialApp(
          title: stealthProvider.isStealthMode ? stealthProvider.disguiseName : 'Whispr',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF1A1A2E),
            scaffoldBackgroundColor: const Color(0xFF0F0F1E),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF6C63FF),
              secondary: const Color(0xFF00D9FF),
              surface: const Color(0xFF1A1A2E),
              background: const Color(0xFF0F0F1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1A2E),
              elevation: 0,
            ),
            cardTheme: CardTheme(
              color: const Color(0xFF1A1A2E),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/identity-setup': (context) => const IdentitySetupScreen(),
            '/home': (context) => const HomeScreen(),
            '/chat': (context) => const ChatScreen(),
            '/qr-scan': (context) => const QRScanScreen(),
            '/stealth-mode': (context) => const StealthModeScreen(),
          },
        );
      },
    );
  }
}
