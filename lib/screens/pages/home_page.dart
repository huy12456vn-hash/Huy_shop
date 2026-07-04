import 'package:flutter/material.dart';
import '../../widgets/banner_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<String> lstBanner = [
    'assets/images/summer_gucci.png',
    'assets/images/gucci_summer1.png',
    'assets/images/gucci_sumemr2.png'
  ];

  final List<Map<String, dynamic>> categories = [
  {
    'label': 'Túi xách',
    'icon': const Icon(
      Icons.shopping_bag_outlined,
      color: Colors.black87,
      size: 24,
    ),
  },
  {
    'label': 'Giày dép',
    'icon':  PhosphorIcon(
      PhosphorIcons.sneaker(),
      color: Colors.black87,
      size: 24,
    ),
  },
  {
    'label': 'Thời trang nữ',
    'icon': const Icon(
      Icons.female,
      color: Colors.black87,
      size: 24,
    ),
  },
  {
    'label': 'Thời trang nam',
    'icon': const Icon(
      Icons.male,
      color: Colors.black87,
      size: 24,
    ),
  },
];

  final List<Map<String, String>> products = [
    {'name': 'Túi đeo vai Ophidia GG', 'price': '59.000.000 đ'},
    {'name': 'Giày sneaker Ace', 'price': '24.500.000 đ'},
    {'name': 'Thắt lưng GG Marmont', 'price': '16.800.000 đ'},
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
                    _buildSectionHeader('DANH MỤC NỔI BẬT'),
                    const SizedBox(height: 14),
                    _buildCategoryList(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('SẢN PHẨM MỚI'),
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
              Text('Xem tất cả', style: TextStyle(fontSize: 12, color: Colors.black54)),
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

  Widget _buildProductList() {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: const Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.favorite_border, size: 18),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product['price']!,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              'Những món quà ý nghĩa cho người đặc biệt.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
