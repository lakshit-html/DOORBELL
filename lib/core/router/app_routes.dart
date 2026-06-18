/// Centralised route paths and names. Use [AppRoutes] constants instead of raw
/// strings so a path change is a single edit.
class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const phoneLogin = '/phone-login';

  // Customer
  static const home = '/home';
  static const search = '/search';
  static const orders = '/orders';
  static const profile = '/profile';
  static const shopDetail = '/shop'; // /shop/:id
  static const productDetail = '/product'; // /product/:id
  static const categoryProducts = '/category'; // /category/:id
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const tracking = '/tracking'; // /tracking/:orderId
  static const wallet = '/wallet';
  static const notifications = '/notifications';
  static const addresses = '/addresses';

  // Seller
  static const seller = '/seller';
  static const sellerRegister = '/seller/register';

  // Rider
  static const rider = '/rider';
  static const riderRegister = '/rider/register';

  // Admin
  static const admin = '/admin';

  // E-Mitra
  static const emitra = '/emitra';

  static String shop(String id) => '$shopDetail/$id';
  static String product(String id) => '$productDetail/$id';
  static String category(String id) => '$categoryProducts/$id';
  static String track(String orderId) => '$tracking/$orderId';
}
