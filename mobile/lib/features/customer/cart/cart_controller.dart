import 'package:creavers_delivery_mobile/core/models/catalogue.dart';
import 'package:flutter/foundation.dart';

final class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;
}

final class CartController extends ChangeNotifier {
  static const double deliveryFee = 80;
  static const int maximumQuantity = 50;

  final Map<String, CartLine> _lines = <String, CartLine>{};

  List<CartLine> get lines => List<CartLine>.unmodifiable(_lines.values);
  bool get isEmpty => _lines.isEmpty;
  int get distinctItemCount => _lines.length;
  int get itemCount =>
      _lines.values.fold<int>(0, (total, line) => total + line.quantity);
  double get subtotal =>
      _lines.values.fold<double>(0, (total, line) => total + line.lineTotal);
  double get total => isEmpty ? 0 : subtotal + deliveryFee;

  int quantityFor(Product product) => _lines[product.id]?.quantity ?? 0;

  void add(Product product) {
    final current = quantityFor(product);
    if (current >= maximumQuantity) return;
    _lines[product.id] = CartLine(product: product, quantity: current + 1);
    notifyListeners();
  }

  void decrement(Product product) {
    final current = quantityFor(product);
    if (current <= 1) {
      remove(product);
      return;
    }
    _lines[product.id] = CartLine(product: product, quantity: current - 1);
    notifyListeners();
  }

  void remove(Product product) {
    if (_lines.remove(product.id) != null) notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}
