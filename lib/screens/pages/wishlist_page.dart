import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'product_detail_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../l10n/app_strings.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

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

  Future<void> _removeFromWishlist(
    BuildContext context,
    String wishlistDocumentId,
    AppStrings s,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('wishlists')
          .doc(wishlistDocumentId)
          .delete();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.itemRemovedFromWishlistShort),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.unableToRemoveItem(error.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final s = AppStrings(locale);
        final User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline, size: 75, color: Colors.black38),
                    const SizedBox(height: 18),
                    Text(
                      s.notSignedInTitle,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.signInToViewFavorites,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('wishlists')
                .where('userId', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text(
                      s.unableToLoadWishlist(snapshot.error.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyWishlist(s);
              }

              final wishlistDocuments = [...snapshot.data!.docs];

              wishlistDocuments.sort((first, second) {
                final firstTime = first.data()['createdAt'] as Timestamp?;
                final secondTime = second.data()['createdAt'] as Timestamp?;

                if (firstTime == null && secondTime == null) {
                  return 0;
                }

                if (firstTime == null) {
                  return 1;
                }

                if (secondTime == null) {
                  return -1;
                }

                return secondTime.compareTo(firstTime);
              });

              return MasonryGridView.count(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                itemCount: wishlistDocuments.length,
                itemBuilder: (context, index) {
                  final document = wishlistDocuments[index];
                  final product = document.data();

                  return _buildWishlistCard(
                    context: context,
                    wishlistDocumentId: document.id,
                    product: product,
                    s: s,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyWishlist(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 85, color: Colors.black26),
            const SizedBox(height: 20),
            Text(
              s.wishlistEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              s.wishlistEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard({
    required BuildContext context,
    required String wishlistDocumentId,
    required Map<String, dynamic> product,
    required AppStrings s,
  }) {
    final String productName = (product['name'] ?? s.untitledProduct).toString();

    final dynamic productPrice = product['price'] ?? 0;

    final String imageBase64 = (product['image'] ?? '').toString();

    final Uint8List? imageBytes = _decodeProductImage(imageBase64);

    final String productId = (product['productId'] ?? '').toString();

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
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: imageBytes == null
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Image.memory(
                            imageBytes,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
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
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: s.removeFromWishlistTooltip,
                      onPressed: () {
                        _removeFromWishlist(context, wishlistDocumentId, s);
                      },
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.black,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.formatPrice(productPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
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