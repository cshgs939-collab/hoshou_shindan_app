import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'data/models/app_settings.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/screens/diagnosis/calculating_screen.dart';
import 'presentation/screens/diagnosis/diagnosis_steps.dart';
import 'presentation/screens/history/compare_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/result/result_dashboard_screen.dart';
import 'presentation/screens/scenario/scenario_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/widgets/web_shell.dart';

class MamoruApp extends ConsumerWidget {
  const MamoruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'まもる計算',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light, settings),
      darkTheme: _buildTheme(Brightness.dark, settings),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return WebShell(child: child);
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness, AppSettings settings) {
    final scale = switch (settings.fontSize) {
      0 => 0.9,
      2 => 1.15,
      _ => 1.0,
    };

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: brightness == Brightness.light
            ? AppColors.surface
            : const Color(0xFF1C1B1F),
      ),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.surface
          : const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: brightness == Brightness.light
            ? AppColors.surface
            : const Color(0xFF121212),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: scale),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/diagnosis/step1',
        builder: (context, state) => const Step1Screen(),
      ),
      GoRoute(
        path: '/diagnosis/step2',
        builder: (context, state) => const Step2Screen(),
      ),
      GoRoute(
        path: '/diagnosis/step3',
        builder: (context, state) => const Step3Screen(),
      ),
      GoRoute(
        path: '/diagnosis/calculating',
        builder: (context, state) => const CalculatingScreen(),
      ),
      GoRoute(
        path: '/result/:id',
        builder: (context, state) => ResultDashboardScreen(
          resultId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/compare',
        builder: (context, state) => const CompareScreen(),
      ),
      GoRoute(
        path: '/scenario',
        builder: (context, state) => ScenarioScreen(
          resultId: state.uri.queryParameters['resultId'],
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
