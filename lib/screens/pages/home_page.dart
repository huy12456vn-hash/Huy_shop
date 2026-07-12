import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../widgets/banner_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Removed phosphor_flutter; using built-in Material icons instead.

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<String> lstBanner = [
    'assets/images/summer_gucci.png',
    'assets/images/gucci_summer1.png',
    'assets/images/gucci_sumemr2.png'
  ];

  final List<Map<String, dynamic>> categories = [
  {
    'label': 'Handbags',
    'icon': const Icon(
      Icons.shopping_bag_outlined,
      color: Colors.black87,
      size: 24,
    ),
  },
  {
    'label': 'Shoes',
    'icon': const Icon(
      Icons.directions_run,
      color: Colors.black87,
      size: 24,
    ),
  },
  {
    'label': 'Women\'s Fashion',
    'icon': const Icon(
      Icons.female,
      color: Colors.black87,
      size: 24,
    ),
  },
  {
    'label': 'Men\'s Fashion',
    'icon': const Icon(
      Icons.male,
      color: Colors.black87,
      size: 24,
    ),
  },
];

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(height: 5,),
                    _buildBanner(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('FEATURED CATEGORIES'),
                    const SizedBox(height: 14),
                    _buildCategoryList(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('NEW ARRIVALS'),
                    const SizedBox(height: 14),
                    _buildProductList(),
                    const SizedBox(height: 20),
                    _buildGiftingBanner(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return BannerWidget(
      images: lstBanner,
      height: 250,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Row(
            children: const [
              Text('View all', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Icon(Icons.chevron_right, size: 16, color: Colors.black54),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = categories[index];
          return Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: item['icon'] as Widget,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 72,
                child: Text(
                  item['label'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Decode chuỗi base64 lưu trong Firestore ra ảnh. Trả về null nếu
  /// rỗng hoặc chuỗi không hợp lệ (tránh crash toàn app khi có dữ liệu lỗi).
  Uint8List? _decodeProductImage(String base64String) {
    if (base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

Widget _buildProductList() {
  return SizedBox(
    height: 290,
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No products"),
          );
        }

        final products = snapshot.data!.docs;

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product =
                products[index].data() as Map<String, dynamic>;

            final imageBase64 = (product["image"] ?? "").toString();
            final imageBytes = _decodeProductImage(imageBase64);
            final name = product["name"] ?? "";
            final price = product["price"] ?? 0;

            return Container(
              width: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// IMAGE
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: imageBytes == null
                            ? Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image),
                                ),
                              )
                            : Image.memory(
                                imageBytes,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 150,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                      ),

                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.favorite_border),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [

                            Expanded(
                              child: Text(
                                "${price.toString()} VND",
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
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
                                onPressed: () {},
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

  Widget _buildGiftingBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3D2F),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('GUCCI', style: TextStyle(color: Colors.white70, letterSpacing: 3, fontSize: 12)),
            Text('GIFTING', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(
              'Meaningful gifts for someone special.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}