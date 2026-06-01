import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './core/theme/app_theme.dart';
import './core/providers/auth_provider.dart';
import './core/providers/theme_provider.dart';
import './screens/splash_screen.dart';
import './screens/app_shell.dart';

class TabzApp extends StatefulWidget {
  const TabzApp({super.key});

  @override
  State<TabzApp> createState() => _TabzAppState();
}

class _TabzAppState extends State<TabzApp> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication state and theme on app startup
    Future.microtask(() {
      context.read<ThemeProvider>().initializeTheme();
      context.read<AuthProvider>().initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Tabz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        final c = AppDynColors.of(context);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: c.gradientBackground,
              stops: const [0.0, 1.0],
            ),
          ),
          child: child,
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Wait for auth initialization
          if (!auth.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (auth.isAuthenticated) {
            return const AppShell();
          }
          return const SplashScreen();
        },
      ),
    );
  }
}
