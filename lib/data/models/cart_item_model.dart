import 'product_model.dart';

/// A product plus quantity, held in the cart. The cart is local (Riverpod) and
/// only serialised into the order on checkout.
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final ProductModel product;
  final int quantity;

  double get lineTotal => product.effectivePrice * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  /// Snapshot stored on the order document (price captured at purchase time).
  Map<String, dynamic> toOrderMap() => {
        'productId': product.productId,
        'name': product.name,
        'image': product.image,
        'price': product.effectivePrice,
        'quantity': quantity,
        'lineTotal': lineTotal,
      };
}
