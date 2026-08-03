import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'dart:convert';
import 'product_detail_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _results = [];
  bool _isLoading = false;
  String _keyword = '';

  Future<void> _searchProducts(String keyword) async {
  setState(() {
    _isLoading = true;
    _keyword = keyword;
  });

  if (keyword.trim().isEmpty) {
    setState(() {
      _results = [];
      _isLoading = false;
    });
    return;
  }

  try {
    // Lấy toàn bộ sản phẩm rồi lọc ở client (đơn giản, không cần index/field phụ)
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    final String lowerKeyword = keyword.toLowerCase().trim();

    final List<ProductModel> products = snapshot.docs
        .map((doc) =>
            ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((product) => product.name.toLowerCase().contains(lowerKeyword))
        .toList();

    setState(() {
      _results = products;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    debugPrint('Lỗi tìm kiếm: $e');
  }
}

  String _formatPrice(dynamic value) {
    final input = value?.toString() ?? '0';
    final normalized = input.replaceAll(RegExp(r'[^0-9,.-]'), '');
    final parsed = normalized.isEmpty
        ? 0
        : num.tryParse(normalized.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final usdAmount = parsed / 26300;
    final cents = (usdAmount * 100).round();
    final whole = cents ~/ 100;
    final fraction = (cents % 100).abs().toString().padLeft(2, '0');
    final digits = whole.toString();
    final buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      final positionFromRight = digits.length - index;
      buffer.write(digits[index]);
      if (positionFromRight > 1 && positionFromRight % 3 == 1) {
        buffer.write(',');
      }
    }

    return '\$${buffer.toString()}.$fraction';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 1,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _searchProducts(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _searchProducts('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_keyword.isEmpty) {
      return const Center(
        child: Text(
          'Nhập từ khóa để tìm sản phẩm',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy sản phẩm nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return MasonryGridView.count(
  padding: const EdgeInsets.all(12),
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  itemCount: _results.length,
  itemBuilder: (context, index) {
    final product = _results[index];
    return _buildProductCard(product);
  },
);
  }

  Widget _buildProductCard(ProductModel product) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(product: product),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: product.image.isNotEmpty
                  ? Image.memory(
                      base64Decode(product.image),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(product.price), // bỏ luôn dấu $ thừa, xem lưu ý bên dưới
                  style: const TextStyle(color: Colors.grey),
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