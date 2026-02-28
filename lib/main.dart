import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'providers/library_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/admin_analytics_provider.dart';
import 'providers/review_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => AdminAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProxyProvider<AppAuthProvider, WalletProvider>(
          create: (context) => WalletProvider(Provider.of<AppAuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous!..update(auth),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, ReservationProvider>(
          create: (context) => ReservationProvider(Provider.of<AppAuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous!..update(auth),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use userTheme as default. The admin screens handle their own styling 
    // via the admin AppBar theme. This avoids rebuilding MaterialApp on auth changes.
    return MaterialApp(
      title: 'Public Library',
      theme: AppTheme.userTheme,
      home: const _AppEntry(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return Consumer<AppAuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: AppColors.splashGradient),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        if (auth.isAdmin) {
          return const AdminHomeScreen();
        }

        return const MainScreen();
      },
    );
  }
}
