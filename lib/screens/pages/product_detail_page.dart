import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;
  const ProductDetailPage({super.key, required this.product});

  String _formatPrice(String price) {
    final digitsOnly = price.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return price;
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      final posFromRight = digitsOnly.length - i;
      buffer.write(digitsOnly[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  Widget _roundIconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: _roundIconButton(context, Icons.arrow_back, () => Navigator.pop(context)),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 4),
                child: _roundIconButton(context, Icons.favorite_border, () {}),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.image.isNotEmpty
                  ? Image.memory(
                      base64Decode(product.image),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_formatPrice(product.price)} ₫',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 20),
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty ? product.description : 'Chưa có mô tả cho sản phẩm này.',
                    style: TextStyle(fontSize: 14, height: 1.7, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3)),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã thêm vào giỏ hàng'), duration: Duration(seconds: 1)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text(
              'Thêm vào giỏ hàng',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}