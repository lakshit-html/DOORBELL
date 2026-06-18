import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/admin_providers.dart';
import '../../screens/admin_shell.dart';
import '../../screens/login_screen.dart';

class _AdminRouterNotifier extends ChangeNotifier {
  _AdminRouterNotifier(this.ref) {
    _subs = [
      ref.listen(authStateProvider, (_, __) => notifyListeners()),
      ref.listen(adminUserProvider, (_, __) => notifyListeners()),
    ];
  }

  final Ref ref;
  late final List<ProviderSubscription> _subs;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    if (authState.isLoading) return null;
    final loggedIn = authState.value != null;
    final loc = state.matchedLocation;
    final isLoginRoute = loc == '/login';

    if (!loggedIn) return isLoginRoute ? null : '/login';

    final profile = ref.read(adminUserProvider).value;
    if (profile == null) return null;

    // Only admins allowed
    if (profile.role.name != 'admin') {
      // Sign out non-admin users
      ref.read(firebaseAuthProvider).signOut();
      return '/login';
    }

    if (isLoginRoute) return '/';
    return null;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    super.dispose();
  }
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AdminRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const AdminShell(selectedIndex: 0),
      ),
      GoRoute(
        path: '/users',
        builder: (_, __) => const AdminShell(selectedIndex: 1),
      ),
      GoRoute(
        path: '/shops',
        builder: (_, __) => const AdminShell(selectedIndex: 2),
      ),
      GoRoute(
        path: '/riders',
        builder: (_, __) => const AdminShell(selectedIndex: 3),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const AdminShell(selectedIndex: 4),
      ),
      GoRoute(
        path: '/products',
        builder: (_, __) => const AdminShell(selectedIndex: 5),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const AdminShell(selectedIndex: 6),
      ),
      GoRoute(
        path: '/analytics',
        builder: (_, __) => const AdminShell(selectedIndex: 7),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const AdminShell(selectedIndex: 8),
      ),
    ],
  );
});
