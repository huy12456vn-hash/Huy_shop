import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CollectionReference<Map<String, dynamic>> _categoriesRef =
      FirebaseFirestore.instance.collection('categories');
  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');

  // null nghĩa là đang chọn "All"
  String? _selectedCategoryId;

  Uint8List? _decodeProductImage(String base64String) {
    if (base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
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
        // Danh mục tạo trước (cũ) hiện trước, danh mục mới tạo hiện sau
        stream: _categoriesRef.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          final categoryDocs = snapshot.data?.docs ?? [];

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildChip(
                label: 'All',
                selected: _selectedCategoryId == null,
                onTap: () => setState(() => _selectedCategoryId = null),
              ),
              const SizedBox(width: 8),
              ...categoryDocs.map((doc) {
                final data = doc.data();
                final name = data['name']?.toString() ?? 'Không tên';
                final selected = _selectedCategoryId == doc.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(
                    label: name,
                    selected: selected,
                    onTap: () => setState(() => _selectedCategoryId = doc.id),
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
    // Khi chọn "All": chỉ orderBy (không where) -> không cần composite index.
    // Khi chọn 1 danh mục cụ thể: chỉ where (không orderBy ở server) để
    // tránh phải tạo composite index; sắp xếp lại theo createdAt ngay
    // trong Dart sau khi nhận dữ liệu.
    final bool isFilteringByCategory = _selectedCategoryId != null;

    final Query<Map<String, dynamic>> query = isFilteringByCategory
        ? _productsRef.where('categoryId', isEqualTo: _selectedCategoryId)
        : _productsRef.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Đã xảy ra lỗi khi tải sản phẩm.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không có sản phẩm nào trong danh mục này.'));
        }

        var products = snapshot.data!.docs;

        // Nếu đang lọc theo danh mục (không orderBy ở server), sắp xếp lại
        // theo createdAt mới nhất trước, ngay trong bộ nhớ.
        if (isFilteringByCategory) {
          products = [...products]..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // mới nhất trước
            });
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (context, index) {
            final product = products[index].data();
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageBase64 = (product["image"] ?? "").toString();
    final imageBytes = _decodeProductImage(imageBase64);
    final name = product["name"] ?? "";
    final price = product["price"] ?? 0;

    return Container(
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 1.05, // ảnh tự co giãn theo chiều rộng ô lưới
                  child: imageBytes == null
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.image)),
                        )
                      : Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image)),
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${price.toString()} VND",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        onPressed: () {},
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
}