import 'product_model.dart';

class CartItemModel {
  final String productId;
  final String name;
  final double price;
  final String image;
  final String categoryId;
  final String description;
  final int quantity;
  final String size;
  final List<String> availableSizes;

  const CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.categoryId,
    required this.description,
    required this.quantity,
    this.size = '',
    this.availableSizes = const [],
  });

  /// Khóa duy nhất cho từng dòng trong giỏ hàng.
  /// Cùng 1 sản phẩm nhưng khác size sẽ có cartKey khác nhau,
  /// nên được coi là 2 dòng riêng biệt trong giỏ hàng.
  String get cartKey => size.isEmpty ? productId : '$productId::$size';

  factory CartItemModel.fromProduct(
    ProductModel product, {
    int quantity = 1,
    String size = '',
  }) {
    return CartItemModel(
      productId: product.id,
      name: product.name,
      price: _parsePrice(product.price),
      image: product.image,
      categoryId: product.categoryId,
      description: product.description,
      quantity: quantity,
      size: size,
      availableSizes: product.sizes,
    );
  }

  factory CartItemModel.fromMap(Map<dynamic, dynamic> map) {
    return CartItemModel(
      productId: (map['productId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      price: _parsePrice(map['price']),
      image: (map['image'] ?? '').toString(),
      categoryId: (map['categoryId'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      quantity: _parseQuantity(map['quantity']),
      size: (map['size'] ?? '').toString(),
      availableSizes:
          (map['availableSizes'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'image': image,
      'categoryId': categoryId,
      'description': description,
      'quantity': quantity,
      'size': size,
      'availableSizes': availableSizes,
    };
  }

  CartItemModel copyWith({
    String? productId,
    String? name,
    double? price,
    String? image,
    String? categoryId,
    String? description,
    int? quantity,
    String? size,
    List<String>? availableSizes,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      availableSizes: availableSizes ?? this.availableSizes,
    );
  }

  double get subtotal => price * quantity;

  static double _parsePrice(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String raw = value.toString().trim();

    // Thử parse trực tiếp trước — xử lý đúng các chuỗi số thuần,
    // kể cả có dấu chấm thập phân (vd "8900000.0" từ Firestore
    // khi trường price được lưu dạng double rồi gọi .toString()).
    // Nếu không làm bước này trước, dấu chấm thập phân sẽ bị hiểu nhầm
    // thành dấu phân cách hàng nghìn ở bước dưới và bị xóa,
    // khiến giá trị bị nhân lên gấp 10 lần (8900000.0 -> 89000000).
    final double? direct = double.tryParse(raw);
    if (direct != null) {
      return direct;
    }

    // Chỉ khi parse trực tiếp thất bại (chuỗi đã format kiểu tiền tệ,
    // vd "8.900.000đ", "8,900,000 VND"...) mới bóc tách ký hiệu
    // và dấu phân cách hàng nghìn.
    final String normalizedValue = raw
        .replaceAll('VND', '')
        .replaceAll('₫', '')
        .replaceAll('\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(normalizedValue) ?? 0;
  }

  static int _parseQuantity(dynamic value) {
    if (value is int && value > 0) {
      return value;
    }

    final int parsedValue = int.tryParse(value.toString()) ?? 1;

    return parsedValue > 0 ? parsedValue : 1;
  }
}