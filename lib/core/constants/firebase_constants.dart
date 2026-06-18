/// Centralised Firestore collection and Storage path names.
///
/// Keeping these in one place avoids typo-bugs across repositories and makes
/// renaming a collection a one-line change.
class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String shops = 'shops';
  static const String riders = 'riders';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String orders = 'orders';
  static const String reviews = 'reviews';
  static const String wallets = 'wallets';
  static const String notifications = 'notifications';
  static const String supportTickets = 'supportTickets';
  static const String coupons = 'coupons';

  // Sub-collections
  static const String addresses = 'addresses';
  static const String transactions = 'transactions';
}

class StoragePaths {
  const StoragePaths._();

  static String userProfile(String uid) => 'users/$uid/profile.jpg';
  static String shopImages(String shopId) => 'shops/$shopId/images';
  static String productImages(String productId) => 'products/$productId';
  static String riderDocs(String riderId) => 'riders/$riderId/documents';
}
