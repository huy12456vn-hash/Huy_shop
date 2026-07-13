import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        const SnackBar(
          content: Text('Đã xóa sản phẩm khỏi Wishlist'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể xóa sản phẩm: $error')));
    }
  }

  String _formatPrice(dynamic value) {
    if (value == null) {
      return '0 VND';
    }

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

    return '${buffer.toString()} VND';
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 75, color: Colors.black38),
                SizedBox(height: 18),
                Text(
                  'Bạn chưa đăng nhập',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Vui lòng đăng nhập để xem sản phẩm yêu thích.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                  'Không thể tải Wishlist.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyWishlist();
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

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: wishlistDocuments.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final document = wishlistDocuments[index];

              final product = document.data();

              return _buildWishlistCard(
                context: context,
                wishlistDocumentId: document.id,
                product: product,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 85, color: Colors.black26),
            SizedBox(height: 20),
            Text(
              'Your wishlist is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Nhấn vào biểu tượng trái tim để lưu những sản phẩm bạn yêu thích.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
  }) {
    final String productName = (product['name'] ?? 'Không tên').toString();

    final dynamic productPrice = product['price'] ?? 0;

    final String imageBase64 = (product['image'] ?? '').toString();

    final Uint8List? imageBytes = _decodeProductImage(imageBase64);

    return Container(
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
                  aspectRatio: 1.05,
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
                    tooltip: 'Xóa khỏi Wishlist',
                    onPressed: () {
                      _removeFromWishlist(context, wishlistDocumentId);
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
            padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
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
                const SizedBox(height: 10),
                Text(
                  _formatPrice(productPrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
