import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/admin/admin_hub_screen.dart';
import '../../screens/global_schedule_search_screen.dart';
import '../../screens/contacts_screen.dart';

class AppRouter {
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
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminHubScreen()),
        GoRoute(path: '/search-schedules', builder: (_, __) => const GlobalScheduleSearchScreen()),
        GoRoute(path: '/contacts', builder: (_, __) => const ContactsScreen()),
      ],
    );
  }
}
