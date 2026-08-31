import 'package:creavers_delivery_mobile/core/models/catalogue.dart';
import 'package:creavers_delivery_mobile/features/customer/cart/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const milk = Product(
    id: 'milk-id',
    name: 'Fresh Milk',
    description: 'Pasteurized milk',
    unit: '1 litre',
    price: 60,
    imageUrl: '/images/milk.png',
  );

  test('cart calculates quantities, subtotal, delivery fee and total', () {
    final cart = CartController();

    cart.add(milk);
    cart.add(milk);

    expect(cart.itemCount, 2);
    expect(cart.distinctItemCount, 1);
    expect(cart.subtotal, 120);
    expect(cart.total, 200);

    cart.decrement(milk);
    expect(cart.quantityFor(milk), 1);
    cart.decrement(milk);
    expect(cart.isEmpty, isTrue);
    expect(cart.total, 0);
  });
}
