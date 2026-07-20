import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  final String? productId;

  const ProductDetailPage({super.key, required this.product, this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  String _selectedSize = 'M';
  String _selectedColor = 'Brown';

  CollectionReference<Map<String, dynamic>> get _wishlistsRef =>
      FirebaseFirestore.instance.collection('wishlists');

  ProductModel get product => widget.product;

  String get _resolvedProductId {
    final id = widget.productId?.trim() ?? '';

    if (id.isNotEmpty) {
      return id;
    }

    return Uri.encodeComponent('${product.name}_${product.price}');
  }

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _heartScale = Tween<double>(begin: 1, end: 1.25).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

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

  String _formatPrice(String price) {
    final digitsOnly = price.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return price;
    }

    final buffer = StringBuffer();

    for (int index = 0; index < digitsOnly.length; index++) {
      final positionFromRight = digitsOnly.length - index;
      buffer.write(digitsOnly[index]);

      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} ₫';
  }

  String _wishlistDocumentId({
    required String userId,
    required String productId,
  }) {
    return '${userId}_$productId';
  }

  Future<void> _toggleWishlist() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage('Please sign in to use the wishlist.');
      return;
    }

    final wishlistId = _wishlistDocumentId(
      userId: currentUser.uid,
      productId: _resolvedProductId,
    );

    final reference = _wishlistsRef.doc(wishlistId);

    try {
      final snapshot = await reference.get();

      await _heartController.forward(from: 0);
      await _heartController.reverse();

      if (snapshot.exists) {
        await reference.delete();

        if (!mounted) return;
        _showMessage('Removed from wishlist.');
      } else {
        await reference.set({
          'userId': currentUser.uid,
          'productId': _resolvedProductId,
          'name': product.name,
          'price': product.price,
          'image': product.image,
          'description': product.description,
          'categoryId': product.categoryId,
          'size': _selectedSize,
          'color': _selectedColor,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        _showMessage('Added to wishlist.');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to update wishlist: $error');
    }
  }

  Future<void> _addToCart() async {
    await context.read<CartProvider>().addProduct(product);

    if (!mounted) return;

    _showMessage(
      '${product.name} ($_selectedSize, $_selectedColor) was added to your cart.',
    );
  }

  Future<void> _buyNow() async {
    await _addToCart();

    if (!mounted) return;

    Navigator.pop(context);
  }

  void _shareProduct() {
    _showMessage('Share feature is ready for the next step.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 23, color: color),
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return ScaleTransition(
        scale: _heartScale,
        child: _roundIconButton(
          icon: Icons.favorite_border,
          onTap: _toggleWishlist,
        ),
      );
    }

    final wishlistId = _wishlistDocumentId(
      userId: currentUser.uid,
      productId: _resolvedProductId,
    );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _wishlistsRef.doc(wishlistId).snapshots(),
      builder: (context, snapshot) {
        final isFavorite = snapshot.hasData && snapshot.data!.exists;

        return ScaleTransition(
          scale: _heartScale,
          child: _roundIconButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.black,
            onTap: _toggleWishlist,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeImage(product.image);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 390,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: false,
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 18, top: 6, bottom: 6),
              child: _roundIconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: _buildWishlistButton(),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(right: 18, top: 6, bottom: 6),
                child: _roundIconButton(
                  icon: Icons.share_outlined,
                  onTap: _shareProduct,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFF1F1F1),
                child: imageBytes == null
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 72,
                          color: Colors.grey,
                        ),
                      )
                    : Image.memory(
                        imageBytes,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 72,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 130),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(
                        5,
                        (_) => const Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '(128 reviews)',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _formatPrice(product.price),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Free delivery',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.verified_user_outlined, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Authentic product',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Size',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: ['S', 'M', 'L', 'XL'].map((size) {
                      final selected = _selectedSize == size;

                      return ChoiceChip(
                        label: Text(size),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedSize = size;
                          });
                        },
                        selectedColor: Colors.black,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: selected ? Colors.black : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Color',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _colorOption(
                        name: 'Brown',
                        color: const Color(0xFFA76135),
                      ),
                      _colorOption(name: 'Black', color: Colors.black),
                      _colorOption(name: 'White', color: Colors.white),
                      _colorOption(
                        name: 'Blue',
                        color: const Color(0xFF28466A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 22),
                  const Text(
                    'Product Description',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.description.trim().isNotEmpty
                        ? product.description
                        : 'No description is available for this product.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  label: const Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _buyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorOption({required String name, required Color color}) {
    final selected = _selectedColor == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = name;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
