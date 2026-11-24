import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/map_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/private_data_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/theme_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/update/update_checker.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  UpdateChecker.instance.start();
  runApp(const NullCoreMapsApp());
}

class NullCoreMapsApp extends StatefulWidget {
  const NullCoreMapsApp({super.key});

  @override
  State<NullCoreMapsApp> createState() => _NullCoreMapsAppState();
}

class _NullCoreMapsAppState extends State<NullCoreMapsApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.create(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => PrivateDataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp.router(
            title: 'NULLCORE MAPS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            routerConfig: _router,
            builder: (context, child) => Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const _UpdateBanner(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Aviso de "nueva versión" (solo web) con botón para recargar.
class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UpdateChecker.instance.updateAvailable,
      builder: (context, available, _) {
        if (!available) return const SizedBox.shrink();
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: AppColors.darkSurface,
              elevation: 6,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.system_update_alt, color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    const Text('Hay una versión nueva', style: TextStyle(color: AppColors.textPrimaryDark)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: UpdateChecker.instance.reload,
                      child: const Text('Recargar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
