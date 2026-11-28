import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/admin/admin_hub_screen.dart';
import '../../screens/about_screen.dart';
import '../../screens/constancias_guide_screen.dart';

class AppRouter {
  /// Rutas solo para la comunidad UPJR (alumnos y admin).
  static const _privatePaths = {'/constancias'};

  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        if (!auth.isReady) return '/splash';
        final path = state.matchedLocation;
        final isLogin = path == '/login';
        if (!auth.isLoggedIn && path != '/login' && path != '/splash') return '/login';
        if (auth.isLoggedIn && isLogin) return '/';
        // Pantallas internas: los invitados no pueden abrirlas ni por URL.
        if (path == '/admin' && !auth.isAdmin) return '/';
        if (_privatePaths.contains(path) && !auth.canSeePrivate) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminHubScreen()),
        GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
        GoRoute(path: '/constancias', builder: (_, __) => const ConstanciasGuideScreen()),
      ],
    );
  }
}
