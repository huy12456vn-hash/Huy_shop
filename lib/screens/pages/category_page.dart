import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import 'product_detail_page.dart';

class CategoryPage extends StatefulWidget {
  final String? initialCategoryId;

  const CategoryPage({super.key, this.initialCategoryId});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CollectionReference<Map<String, dynamic>> _categoriesRef =
      FirebaseFirestore.instance.collection('categories');

  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');

  final CollectionReference<Map<String, dynamic>> _wishlistsRef =
      FirebaseFirestore.instance.collection('wishlists');

  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  Uint8List? _decodeProductImage(String base64String) {
    if (base64String.isEmpty) {
      return null;
    }

    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(dynamic value) {
    final number = value is num ? value : num.tryParse(value.toString()) ?? 0;

    final digits = number.truncate().toString();
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

  String _wishlistDocumentId({
    required String userId,
    required String productId,
  }) {
    return '${userId}_$productId';
  }

  Future<void> _toggleWishlist({
    required BuildContext context,
    required String productId,
    required Map<String, dynamic> product,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use the wishlist.')),
      );
      return;
    }

    final wishlistId = _wishlistDocumentId(
      userId: currentUser.uid,
      productId: productId,
    );

    final wishlistDocument = _wishlistsRef.doc(wishlistId);

    try {
      final snapshot = await wishlistDocument.get();

      if (snapshot.exists) {
        await wishlistDocument.delete();

        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from wishlist.'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        await wishlistDocument.set({
          'userId': currentUser.uid,
          'productId': productId,
          'name': product['name'] ?? '',
          'price': product['price'] ?? 0,
          'image': product['image'] ?? '',
          'description': product['description'] ?? '',
          'categoryId': product['categoryId'] ?? '',
          'categoryName': product['categoryName'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to wishlist.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update wishlist: $error')),
      );
    }
  }

  Widget _buildWishlistButton({
    required BuildContext context,
    required String productId,
    required Map<String, dynamic> product,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _heartButton(
        isFavorite: false,
        onPressed: () {
          _toggleWishlist(
            context: context,
            productId: productId,
            product: product,
          );
        },
      );
    }

    final wishlistId = _wishlistDocumentId(
      userId: currentUser.uid,
      productId: productId,
    );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _wishlistsRef.doc(wishlistId).snapshots(),
      builder: (context, snapshot) {
        final isFavorite = snapshot.hasData && snapshot.data!.exists;

        return _heartButton(
          isFavorite: isFavorite,
          onPressed: () {
            _toggleWishlist(
              context: context,
              productId: productId,
              product: product,
            );
          },
        );
      },
    );
  }

  Widget _heartButton({
    required bool isFavorite,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite
              ? Colors.black
              : const Color.fromARGB(255, 19, 12, 12),
          size: 21,
        ),
      ),
    );
  }

  Future<void> _addProductToCart({
    required BuildContext context,
    required String productId,
    required Map<String, dynamic> product,
  }) async {
    final productModel = ProductModel.fromMap(productId, product);

    await context.read<CartProvider>().addProduct(productModel);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${productModel.name} was added to your cart.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildCategoryChips(),
          const SizedBox(height: 14),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _categoriesRef
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load categories',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final categoryDocs = snapshot.data?.docs ?? [];

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildChip(
                label: 'All',
                selected: _selectedCategoryId == null,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              ...categoryDocs.map((doc) {
                final data = doc.data();
                final name = data['name']?.toString() ?? 'Unnamed';
                final selected = _selectedCategoryId == doc.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(
                    label: name,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = doc.id;
                      });
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final bool isFilteringByCategory = _selectedCategoryId != null;

    final Query<Map<String, dynamic>> query = isFilteringByCategory
        ? _productsRef.where('categoryId', isEqualTo: _selectedCategoryId)
        : _productsRef.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load products.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No products were found in this category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        var products = snapshot.data!.docs;

        if (isFilteringByCategory) {
          products = [...products]
            ..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;

              if (aTime == null && bTime == null) {
                return 0;
              }

              if (aTime == null) {
                return 1;
              }

              if (bTime == null) {
                return -1;
              }

              return bTime.compareTo(aTime);
            });
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.70,
          ),
          itemBuilder: (context, index) {
            final productDocument = products[index];

            return _buildProductCard(
              context: context,
              productId: productDocument.id,
              product: productDocument.data(),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required String productId,
    required Map<String, dynamic> product,
  }) {
    final imageBase64 = (product['image'] ?? '').toString();
    final imageBytes = _decodeProductImage(imageBase64);
    final name = (product['name'] ?? 'Unnamed').toString();
    final price = product['price'] ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: ProductModel.fromMap(productId, product),
              productId: productId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: imageBytes == null
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildWishlistButton(
                    context: context,
                    productId: productId,
                    product: product,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(price),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            _addProductToCart(
                              context: context,
                              productId: productId,
                              product: product,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
