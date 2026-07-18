class ProductModel {
  final String id;
  final String name;
  final String price;
  final String image;
  final String categoryId;
  final String description;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.categoryId,
    required this.description,
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: data['name']?.toString() ?? '',
      price: data['price']?.toString() ?? '', // ✅ convert an toàn dù là int/double/String
      image: data['image']?.toString() ?? '',
      categoryId: data['categoryId']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
    );
  }
}