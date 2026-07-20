import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  static const String _boxName = 'cartBox';

  Box<dynamic> get _cartBox => Hive.box<dynamic>(_boxName);

  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get totalItems {
    return _items.fold(0, (total, item) => total + item.quantity);
  }

  double get totalPrice {
    return _items.fold(0, (total, item) => total + item.subtotal);
  }

  bool containsProduct(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  int quantityOf(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);

    if (index == -1) {
      return 0;
    }

    return _items[index].quantity;
  }

  Future<void> loadCart() async {
    _items.clear();

    for (final key in _cartBox.keys) {
      final dynamic rawData = _cartBox.get(key);

      if (rawData is Map) {
        final item = CartItemModel.fromMap(rawData);
        _items.add(item);
      }
    }

    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    final index = _items.indexWhere((item) => item.productId == product.id);

    if (index == -1) {
      final item = CartItemModel.fromProduct(product);

      _items.add(item);

      await _cartBox.put(item.productId, item.toMap());
    } else {
      final updatedItem = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );

      _items[index] = updatedItem;

      await _cartBox.put(updatedItem.productId, updatedItem.toMap());
    }

    notifyListeners();
  }

  Future<void> increaseQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);

    if (index == -1) {
      return;
    }

    final updatedItem = _items[index].copyWith(
      quantity: _items[index].quantity + 1,
    );

    _items[index] = updatedItem;

    await _cartBox.put(updatedItem.productId, updatedItem.toMap());

    notifyListeners();
  }

  Future<void> decreaseQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);

    if (index == -1) {
      return;
    }

    final currentItem = _items[index];

    if (currentItem.quantity <= 1) {
      await removeProduct(productId);
      return;
    }

    final updatedItem = currentItem.copyWith(
      quantity: currentItem.quantity - 1,
    );

    _items[index] = updatedItem;

    await _cartBox.put(updatedItem.productId, updatedItem.toMap());

    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeProduct(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);

    if (index == -1) {
      return;
    }

    final updatedItem = _items[index].copyWith(quantity: quantity);

    _items[index] = updatedItem;

    await _cartBox.put(updatedItem.productId, updatedItem.toMap());

    notifyListeners();
  }

  Future<void> removeProduct(String productId) async {
    _items.removeWhere((item) => item.productId == productId);

    await _cartBox.delete(productId);

    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();

    await _cartBox.clear();

    notifyListeners();
  }
}
