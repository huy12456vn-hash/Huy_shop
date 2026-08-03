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

  String _keyFor(String productId, String size) {
    return size.isEmpty ? productId : '$productId::$size';
  }

  bool containsProduct(String productId, {String size = ''}) {
    final cartKey = _keyFor(productId, size);
    return _items.any((item) => item.cartKey == cartKey);
  }

  int quantityOf(String productId, {String size = ''}) {
    final cartKey = _keyFor(productId, size);
    final index = _items.indexWhere((item) => item.cartKey == cartKey);

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

  Future<void> addProduct(
    ProductModel product, {
    String size = '',
    int quantity = 1,
  }) async {
    final cartKey = _keyFor(product.id, size);
    final index = _items.indexWhere((item) => item.cartKey == cartKey);

    if (index == -1) {
      final item = CartItemModel.fromProduct(
        product,
        quantity: quantity,
        size: size,
      );

      _items.add(item);

      await _cartBox.put(item.cartKey, item.toMap());
    } else {
      final updatedItem = _items[index].copyWith(
        quantity: _items[index].quantity + quantity,
      );

      _items[index] = updatedItem;

      await _cartBox.put(updatedItem.cartKey, updatedItem.toMap());
    }

    notifyListeners();
  }

  Future<void> increaseQuantity(String productId, {String size = ''}) async {
    final cartKey = _keyFor(productId, size);
    final index = _items.indexWhere((item) => item.cartKey == cartKey);

    if (index == -1) {
      return;
    }

    final updatedItem = _items[index].copyWith(
      quantity: _items[index].quantity + 1,
    );

    _items[index] = updatedItem;

    await _cartBox.put(updatedItem.cartKey, updatedItem.toMap());

    notifyListeners();
  }

  Future<void> decreaseQuantity(String productId, {String size = ''}) async {
    final cartKey = _keyFor(productId, size);
    final index = _items.indexWhere((item) => item.cartKey == cartKey);

    if (index == -1) {
      return;
    }

    final currentItem = _items[index];

    if (currentItem.quantity <= 1) {
      await removeProduct(productId, size: size);
      return;
    }

    final updatedItem = currentItem.copyWith(
      quantity: currentItem.quantity - 1,
    );

    _items[index] = updatedItem;

    await _cartBox.put(updatedItem.cartKey, updatedItem.toMap());

    notifyListeners();
  }

  Future<void> updateQuantity(
    String productId,
    int quantity, {
    String size = '',
  }) async {
    if (quantity <= 0) {
      await removeProduct(productId, size: size);
      return;
    }

    final cartKey = _keyFor(productId, size);
    final index = _items.indexWhere((item) => item.cartKey == cartKey);

    if (index == -1) {
      return;
    }

    final updatedItem = _items[index].copyWith(quantity: quantity);

    _items[index] = updatedItem;

    await _cartBox.put(updatedItem.cartKey, updatedItem.toMap());

    notifyListeners();
  }

  /// Đổi size của một dòng đã có trong giỏ hàng.
  /// Nếu size mới trùng với một dòng khác (cùng productId),
  /// số lượng sẽ được gộp lại vào dòng đó.
  Future<void> updateSize(
    String productId, {
    required String oldSize,
    required String newSize,
  }) async {
    if (oldSize == newSize) {
      return;
    }

    final oldKey = _keyFor(productId, oldSize);
    final oldIndex = _items.indexWhere((item) => item.cartKey == oldKey);

    if (oldIndex == -1) {
      return;
    }

    final oldItem = _items[oldIndex];
    final newKey = _keyFor(productId, newSize);
    final existingNewIndex = _items.indexWhere(
      (item) => item.cartKey == newKey,
    );

    // Xóa dòng cũ khỏi list và Hive trước.
    _items.removeAt(oldIndex);
    await _cartBox.delete(oldKey);

    if (existingNewIndex != -1) {
      // Đã có dòng với size mới -> gộp số lượng vào dòng đó.
      final targetIndex = _items.indexWhere((item) => item.cartKey == newKey);
      final mergedItem = _items[targetIndex].copyWith(
        quantity: _items[targetIndex].quantity + oldItem.quantity,
      );

      _items[targetIndex] = mergedItem;

      await _cartBox.put(mergedItem.cartKey, mergedItem.toMap());
    } else {
      final updatedItem = oldItem.copyWith(size: newSize);

      _items.add(updatedItem);

      await _cartBox.put(updatedItem.cartKey, updatedItem.toMap());
    }

    notifyListeners();
  }

  Future<void> removeProduct(String productId, {String size = ''}) async {
    final cartKey = _keyFor(productId, size);

    _items.removeWhere((item) => item.cartKey == cartKey);

    await _cartBox.delete(cartKey);

    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();

    await _cartBox.clear();

    notifyListeners();
  }
}