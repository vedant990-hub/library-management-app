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
import 'providers/review_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/stats_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => AdminAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProxyProvider2<AppAuthProvider, LibraryProvider, RecommendationProvider>(
          create: (context) => RecommendationProvider(),
          update: (context, auth, library, previous) => (previous ?? RecommendationProvider())..updateRecommendations(auth, library),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, WalletProvider>(
          create: (context) => WalletProvider(Provider.of<AppAuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous!..update(auth),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, StatsProvider>(
          create: (context) => StatsProvider(),
          update: (context, auth, previous) => (previous ?? StatsProvider())..fetchStats(auth),
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
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, _) {
        final isAdmin = authProvider.isAdmin;
        return MaterialApp(
          title: 'Public Library',
          theme: isAdmin ? AppTheme.adminTheme : AppTheme.userTheme,
          themeMode: ThemeMode.light,
          home: const _AppEntry(),
          debugShowCheckedModeBanner: false,
        );
      },
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
