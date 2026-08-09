import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/banner_widget.dart';
import '../../l10n/app_strings.dart';
import 'category_page.dart';
import 'product_detail_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<String> lstBanner = [
    'assets/images/summer_gucci.png',
    'assets/images/gucci_summer1.png',
    'assets/images/gucci_sumemr2.png',
  ];

  final CollectionReference<Map<String, dynamic>> _categoriesRef =
      FirebaseFirestore.instance.collection('categories');

  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');

  final CollectionReference<Map<String, dynamic>> _wishlistsRef =
      FirebaseFirestore.instance.collection('wishlists');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final t = AppStrings(locale);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),

                        _buildBanner(),

                        const SizedBox(height: 20),

                        _buildSectionHeader(
                          title: t.featuredCategories,
                          onViewAll: () {
                            _openCategoryPage(context, t);
                          },
                        ),

                        const SizedBox(height: 14),

                        _buildCategoryList(context, t),

                        const SizedBox(height: 20),

                        _buildSectionHeader(
                          title: t.newArrivals,
                          onViewAll: () {
                            _openCategoryPage(context, t);
                          },
                        ),

                        const SizedBox(height: 14),

                        _buildProductList(t),

                        const SizedBox(height: 20),

                        _buildSectionHeader(
                          title: t.allProducts,
                          onViewAll: () {
                            _openCategoryPage(context, t);
                          },
                        ),

                        const SizedBox(height: 14),

                        _buildAllProductsGrid(t),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    return BannerWidget(images: lstBanner, height: 250);
  }

  void _openCategoryPage(BuildContext context, AppStrings t, {String? categoryId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFF5F5F5),
              elevation: 0,
              centerTitle: true,
              title: Text(
                t.categoryPageTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: CategoryPage(initialCategoryId: categoryId),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => Text(
                      AppStrings.of(context).viewAll,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, AppStrings t) {
    return SizedBox(
      height: 112,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _categoriesRef
            .orderBy('createdAt', descending: false)
            .limit(8)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                t.unableToLoadCategories,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                t.noCategoriesYet,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          final categoryDocs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categoryDocs.length,
            separatorBuilder: (context, index) {
              return const SizedBox(width: 14);
            },
            itemBuilder: (context, index) {
              final categoryDoc = categoryDocs[index];
              final categoryData = categoryDoc.data();

              final categoryName = (categoryData['name'] ?? 'Untitled')
                  .toString();

              return InkWell(
                onTap: () {
                  _openCategoryPage(context, t, categoryId: categoryDoc.id);
                },
                borderRadius: BorderRadius.circular(40),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _getCategoryIcon(categoryName),
                          color: Colors.black87,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        categoryName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('handbag') ||
        name.contains('bag') ||
        name.contains('bag')) {
      return Icons.shopping_bag_outlined;
    }

    if (name.contains('accessories') ||
        name.contains('accessory') ||
        name.contains('accessor') ||
        name.contains('accessories')) {
      return Icons.diamond_outlined;
    }

    if ((name.contains('women') ||
            name.contains('woman') ||
            name.contains('women')) &&
        (name.contains('shoe') ||
            name.contains('shoes') ||
            name.contains('shoes'))) {
      return Icons.auto_awesome_outlined;
    }

    if ((name.contains('men') ||
            name.contains('man') ||
            name.contains('men')) &&
        (name.contains('shoe') ||
            name.contains('shoes') ||
            name.contains('shoes'))) {
      return Icons.business_center_outlined;
    }

    if (name.contains('shoe') ||
        name.contains('shoes') ||
        name.contains('shoes') ||
        name.contains('sneaker')) {
      return Icons.style_outlined;
    }

    if (name.contains('women') ||
        name.contains('woman') ||
        name.contains('women')) {
      return Icons.female;
    }

    if (name.contains('men') || name.contains('man') || name.contains('men')) {
      return Icons.male;
    }

    if (name.contains('jacket') || name.contains('jacket')) {
      return Icons.dry_cleaning_outlined;
    }

    if (name.contains('shirt') ||
        name.contains('t-shirt') ||
        name.contains('shirt')) {
      return Icons.checkroom_outlined;
    }

    if (name.contains('watch') || name.contains('watch')) {
      return Icons.watch_outlined;
    }

    return Icons.category_outlined;
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
    final t = AppStrings.of(context);

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.signInToWishlistShort),
        ),
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
          SnackBar(
            content: Text(t.itemRemovedFromWishlist),
            duration: const Duration(seconds: 1),
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
          SnackBar(
            content: Text(t.itemAddedToWishlist),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.unableToUpdateWishlistShort(error.toString()))),
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
        context: context,
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
          context: context,
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
    required BuildContext context,
    required bool isFavorite,
    required VoidCallback onPressed,
  }) {
    final t = AppStrings.of(context);

    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: isFavorite ? t.removeFromWishlistTooltip : t.addToWishlistTooltip,
        onPressed: onPressed,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 21,
          color: Colors.black,
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
    final t = AppStrings.of(context);

    await context.read<CartProvider>().addProduct(productModel);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.addedToCartHome(productModel.name)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required String productId,
    required Map<String, dynamic> product,
    required AppStrings t,
    double? width,
  }) {
    final imageBase64 = (product['image'] ?? '').toString();

    final imageBytes = _decodeProductImage(imageBase64);

    final name = (product['name'] ?? 'Untitled').toString();

    final price = product['price'] ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: ProductModel.fromMap(productId, product),
            ),
          ),
        );
      },
      child: Container(
        width: width,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: imageBytes == null
                      ? Container(
                          height: 150,
                          width: double.infinity,
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
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: double.infinity,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.formatPrice(price),
                          maxLines: 1,
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

  Widget _buildProductList(AppStrings t) {
    return SizedBox(
      height: 290,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _productsRef
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                t.unableToLoadProductsShort,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(t.noProducts));
          }

          final products = snapshot.data!.docs;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (context, index) {
              return const SizedBox(width: 14);
            },
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDocument = products[index];

              return _buildProductCard(
                context: context,
                productId: productDocument.id,
                product: productDocument.data(),
                t: t,
                width: 170,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAllProductsGrid(AppStrings t) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _productsRef
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: Text(t.unableToLoadProductsShort, style: const TextStyle(color: Colors.grey)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(t.noProductsYet)),
          );
        }

        final products = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDocument = products[index];
              return _buildProductCard(
                context: context,
                productId: productDocument.id,
                product: productDocument.data(),
                t: t,
              );
            },
          ),
        );
      },
    );
  }
}