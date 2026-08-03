class ProductModel {
  final String id;
  final String name;
  final String price;
  final String image;
  final String categoryId;
  final String description;
  final List<String> sizes;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.categoryId,
    required this.description,
    this.sizes = const [],
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: data['name']?.toString() ?? '',
      price: data['price']?.toString() ?? '', // ✅ convert an toàn dù là int/double/String
      image: data['image']?.toString() ?? '',
      categoryId: data['categoryId']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      sizes:
          (data['sizes'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}