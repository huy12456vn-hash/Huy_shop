import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Uint8List? _decodeImage(String image) {
    if (image.isEmpty) {
      return null;
    }

    try {
      return base64Decode(image);
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      final positionFromRight = digits.length - index;
      buffer.write(digits[index]);

      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} ₫';
  }

  Future<void> _confirmClearCart(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear the entire shopping cart?'),
          content: const Text('All products in the cart will be removed..'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      await cartProvider.clearCart();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All products have been removed from the cart.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _confirmRemoveItem(
    BuildContext context,
    CartProvider cartProvider,
    CartItemModel item,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove product?'),
          content: Text(
            'Are you sure you want to remove "${item.name}" from the cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await cartProvider.removeProduct(item.productId);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product removed from cart.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _openCheckout(BuildContext context, CartProvider cartProvider) {
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The shopping cart is empty.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'SHOPPING CART',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              if (cartProvider.items.isNotEmpty)
                IconButton(
                  tooltip: 'Clear entire cart',
                  onPressed: () {
                    _confirmClearCart(context, cartProvider);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: cartProvider.items.isEmpty
              ? _buildEmptyCart(context)
              : _buildCartList(context, cartProvider),
          bottomNavigationBar: cartProvider.items.isEmpty
              ? null
              : _buildBottomBar(context, cartProvider),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 52,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Shopping Cart is Empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your favorite products to the cart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context, CartProvider cartProvider) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      itemCount: cartProvider.items.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final item = cartProvider.items[index];

        return _buildCartItem(context, cartProvider, item);
      },
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartProvider cartProvider,
    CartItemModel item,
  ) {
    final imageBytes = _decodeImage(item.image);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageBytes == null
                ? Container(
                    width: 96,
                    height: 96,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  )
                : Image.memory(
                    imageBytes,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 96,
                        height: 96,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Remove item',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        _confirmRemoveItem(context, cartProvider, item);
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 19,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(item.price),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quantityButton(
                      icon: Icons.remove,
                      onPressed: () {
                        cartProvider.decreaseQuantity(item.productId);
                      },
                    ),
                    SizedBox(
                      width: 34,
                      child: Center(
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _quantityButton(
                      icon: Icons.add,
                      onPressed: () {
                        cartProvider.increaseQuantity(item.productId);
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatPrice(item.subtotal),
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 17, color: Colors.black),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.07),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Total ${cartProvider.totalItems} items',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Spacer(),
                const Text('Total:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  _formatPrice(cartProvider.totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                _openCheckout(context, cartProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
