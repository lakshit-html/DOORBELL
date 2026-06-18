import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../providers/firebase_providers.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/phone_login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/emitra/screens/emitra_screen.dart';
import '../../features/home/screens/customer_shell.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/profile/screens/addresses_screen.dart';
import '../../features/rider/screens/rider_dashboard_screen.dart';
import '../../features/rider/screens/rider_register_screen.dart';
import '../../features/search/category_products_screen.dart';
import '../../features/seller/screens/seller_dashboard_screen.dart';
import '../../features/seller/screens/seller_register_screen.dart';
import '../../features/shop/screens/shop_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import 'app_routes.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this.ref) {
    _subs = [
      ref.listen(authStateProvider, (_, __) => notifyListeners()),
      ref.listen(currentUserProvider, (_, __) => notifyListeners()),
    ];
  }

  final Ref ref;
  late final List<ProviderSubscription> _subs;

  static const _authRoutes = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.forgotPassword,
    AppRoutes.phoneLogin,
  };

  String _homeForRole(UserRole role) => switch (role) {
        UserRole.customer => AppRoutes.home,
        UserRole.shopOwner => AppRoutes.seller,
        UserRole.rider => AppRoutes.rider,
        UserRole.admin => AppRoutes.admin,
      };

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    if (authState.isLoading) return null;
    final loggedIn = authState.value != null;
    final loc = state.matchedLocation;
    final isAuthRoute = _authRoutes.contains(loc);

    if (!loggedIn) return isAuthRoute ? null : AppRoutes.login;

    final profile = ref.read(currentUserProvider).value;
    if (profile == null) return null;
    final roleHome = _homeForRole(profile.role);

    if (isAuthRoute) return roleHome;

    if (loc.startsWith(AppRoutes.admin) && profile.role != UserRole.admin) {
      return roleHome;
    }
    if (loc.startsWith(AppRoutes.seller) && profile.role != UserRole.shopOwner) {
      return roleHome;
    }
    if (loc.startsWith(AppRoutes.rider) && profile.role != UserRole.rider) {
      return roleHome;
    }
    return null;
  }

  @override
  void dispose() {
    for (final s in _subs) { s.close(); }
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [ref.read(analyticsServiceProvider).observer],
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneLogin,
        builder: (_, __) => const PhoneLoginScreen(),
      ),

      // ── Customer ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const CustomerShell(),
      ),
      GoRoute(
        path: '${AppRoutes.shopDetail}/:id',
        builder: (_, s) => ShopDetailScreen(shopId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.productDetail}/:id',
        builder: (_, s) =>
            ProductDetailScreen(productId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.categoryProducts}/:id',
        builder: (_, s) => CategoryProductsScreen(
          categoryId: s.pathParameters['id']!,
          categoryName: s.uri.queryParameters['name'] ?? 'Category',
        ),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.tracking}/:orderId',
        builder: (_, s) =>
            TrackingScreen(orderId: s.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.emitra,
        builder: (_, __) => const EMitraScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (_, __) => const AddressesScreen(),
      ),

      // ── Seller ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.seller,
        builder: (_, __) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerRegister,
        builder: (_, __) => const SellerRegisterScreen(),
      ),

      // ── Rider ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.rider,
        builder: (_, __) => const RiderDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.riderRegister,
        builder: (_, __) => const RiderRegisterScreen(),
      ),

      // ── Admin ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
    ],
  );
});
