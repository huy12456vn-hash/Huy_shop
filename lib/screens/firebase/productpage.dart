import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductFbPageState();
}

class _ProductFbPageState extends State<ProductPage> {
  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference<Map<String, dynamic>> _categoriesRef =
      FirebaseFirestore.instance.collection('categories');
  final TextEditingController _searchController = TextEditingController();

  Uint8List? imageBytes; // ảnh gốc mới chọn (để preview ngay)
  String? imageBase64; // chuỗi base64 sẽ lưu vào Firestore
  bool isProcessingImage = false; // đang resize/encode ảnh

  // Giới hạn an toàn cho 1 field string trong Firestore (~1MB/document).
  // Base64 tăng ~33% dung lượng nên set ngưỡng thấp hơn nhiều để an toàn.
  static const int _maxBase64Length = 700000; // ~700KB base64 (~500KB ảnh gốc)

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showProductDialog([Map<String, dynamic>? product]) async {
    final nameController = TextEditingController(
      text: product?['name']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: product != null ? _formatPriceForDisplay(product['price']) : '',
    );
    final descriptionController = TextEditingController(
      text: product?['description']?.toString() ?? '',
    );

    // Reset đầy đủ mỗi lần mở dialog
    imageBytes = null;
    imageBase64 = product?['image']?.toString();
    isProcessingImage = false;

    String? selectedCategoryId = product?['categoryId']?.toString();
    final productId = product?['id']?.toString();

    final categoriesSnapshot = await _categoriesRef.get();
    final categoryItems = categoriesSnapshot.docs.map((doc) {
      final categoryData = doc.data();
      return DropdownMenuItem<String>(
        value: doc.id,
        child: Text(categoryData['name']?.toString() ?? 'Không tên'),
      );
    }).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ThousandsSeparatorInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Giá sản phẩm',
                        border: OutlineInputBorder(),
                        suffixText: '₫',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: categoryItems,
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Container(
                            height: 170,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.grey.shade100,
                            ),
                            child: imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (imageBase64 != null &&
                                      imageBase64!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(imageBase64!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: isProcessingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.image),
                              label: Text(
                                isProcessingImage
                                    ? "Đang xử lý ảnh..."
                                    : "Import Image",
                              ),
                              onPressed: isProcessingImage
                                  ? null
                                  : () async {
                                      await pickImage(
                                        () => setStateDialog(() {}),
                                        (message) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                        },
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    imageBytes = null;
                    imageBase64 = null;
                    isProcessingImage = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isProcessingImage
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final priceDigitsOnly = priceController.text
                              .replaceAll('.', '')
                              .trim();
                          final price = double.tryParse(priceDigitsOnly);
                          final description = descriptionController.text.trim();

                          if (name.isEmpty ||
                              price == null ||
                              selectedCategoryId == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập đủ thông tin bắt buộc.',
                                ),
                              ),
                            );
                            return;
                          }

                          final categoryDoc = await _categoriesRef
                              .doc(selectedCategoryId)
                              .get();
                          final categoryName = categoryDoc.exists
                              ? (categoryDoc.data()?['name']?.toString() ?? '')
                              : '';

                          if (product == null) {
                            await _productsRef.add({
                              'name': name,
                              'price': price,
                              'description': description,
                              'image': imageBase64 ?? '',
                              'categoryId': selectedCategoryId,
                              'categoryName': categoryName,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          } else {
                            await _productsRef.doc(productId).update({
                              'name': name,
                              'price': price,
                              'description': description,
                              'image': imageBase64 ?? '',
                              'categoryId': selectedCategoryId,
                              'categoryName': categoryName,
                            });
                          }

                          imageBytes = null;
                          imageBase64 = null;

                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                  child: isProcessingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm!')));
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Chọn ảnh, resize xuống kích thước nhỏ rồi encode base64.
  /// [onError] dùng để báo lỗi (ví dụ ảnh vẫn quá nặng) ra SnackBar.
  Future<void> pickImage(
    VoidCallback refresh,
    void Function(String message) onError,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;

      final file = result.files.first;
      final originalBytes = file.bytes;
      if (originalBytes == null) return;

      isProcessingImage = true;
      refresh();

      // Chạy trực tiếp trên main thread (không dùng compute/Isolate vì
      // Isolate.spawn không được hỗ trợ đầy đủ trên Flutter Web và hay
      // gây lỗi). Ảnh đã được giới hạn kích thước nên xử lý vẫn đủ nhanh.
      // Cho UI 1 frame để vẽ trạng thái loading trước khi xử lý nặng.
      await Future.delayed(Duration.zero);
      final resizedBytes = _resizeAndEncodeJpg(originalBytes);

      if (resizedBytes == null) {
        onError('Không thể xử lý ảnh này. Vui lòng chọn ảnh khác.');
        return;
      }

      final encoded = base64Encode(resizedBytes);

      if (encoded.length > _maxBase64Length) {
        onError(
          'Ảnh vẫn quá lớn sau khi nén (${(encoded.length / 1024).toStringAsFixed(0)}KB). '
          'Vui lòng chọn ảnh có độ phân giải nhỏ hơn.',
        );
        return;
      }

      imageBytes = resizedBytes;
      imageBase64 = encoded;
    } catch (e) {
      debugPrint('Lỗi xử lý ảnh: $e');
      onError('Đã xảy ra lỗi khi xử lý ảnh.');
    } finally {
      isProcessingImage = false;
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productsRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (streamSnapshot.hasError) {
                  return const Center(
                    child: Text('Đã xảy ra lỗi khi tải dữ liệu.'),
                  );
                }
                if (!streamSnapshot.hasData ||
                    streamSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có sản phẩm nào.'));
                }

                final products = streamSnapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  return <String, dynamic>{...data, 'id': doc.id};
                }).toList();

                final query = _searchController.text.trim().toLowerCase();
                final filteredProducts = products.where((product) {
                  final name = (product['name']?.toString() ?? '')
                      .toLowerCase();
                  final category = (product['categoryName']?.toString() ?? '')
                      .toLowerCase();
                  final description = (product['description']?.toString() ?? '')
                      .toLowerCase();
                  return query.isEmpty ||
                      name.contains(query) ||
                      category.contains(query) ||
                      description.contains(query);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy sản phẩm phù hợp.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final imageBase64Str = product['image']?.toString() ?? '';
                    final categoryName =
                        product['categoryName']?.toString() ??
                        'Chưa có danh mục';
                    final description =
                        product['description']?.toString() ?? '';
                    final price = product['price'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageBase64Str.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: Image.memory(
                                base64Decode(imageBase64Str),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 160,
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name']?.toString() ??
                                            'Không tên',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        '${price.toString()} ₫',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      categoryName,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (description.isNotEmpty)
                                  Text(
                                    description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildInfoChip(
                                            Icons.star_border,
                                            'Mới',
                                          ),
                                          _buildInfoChip(
                                            Icons.local_shipping_outlined,
                                            'Giao hàng',
                                          ),
                                          _buildInfoChip(
                                            Icons.favorite_border,
                                            'Hot',
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () =>
                                          _showProductDialog(product),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Xác nhận xóa'),
                                          content: const Text(
                                            'Bạn có chắc muốn xóa sản phẩm này?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteProduct(
                                                  product['id'].toString(),
                                                );
                                              },
                                              child: const Text(
                                                'Xóa',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Chèn dấu chấm phân cách hàng nghìn khi người dùng gõ số, ví dụ
/// gõ "11000000" sẽ tự hiển thị thành "11.000.000".
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = _formatDigitsWithDots(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Chèn dấu chấm mỗi 3 chữ số tính từ bên phải, ví dụ "11000000" -> "11.000.000".
String _formatDigitsWithDots(String digitsOnly) {
  final buffer = StringBuffer();
  for (int i = 0; i < digitsOnly.length; i++) {
    final posFromRight = digitsOnly.length - i;
    buffer.write(digitsOnly[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

/// Format giá trị 'price' lấy từ Firestore (num) thành chuỗi có dấu chấm
/// để hiển thị sẵn trong ô nhập khi sửa sản phẩm.
String _formatPriceForDisplay(dynamic priceValue) {
  if (priceValue == null) return '';
  final priceNum = priceValue is num
      ? priceValue
      : num.tryParse(priceValue.toString());
  if (priceNum == null) return '';
  final intPart = priceNum.truncate().toString();
  return _formatDigitsWithDots(intPart);
}

Uint8List? _resizeAndEncodeJpg(Uint8List inputBytes) {
  final decoded = img.decodeImage(inputBytes);
  if (decoded == null) return null;

  img.Image resized = decoded;
  const maxDimension = 600;
  if (decoded.width > maxDimension || decoded.height > maxDimension) {
    resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxDimension)
        : img.copyResize(decoded, height: maxDimension);
  }

  final jpg = img.encodeJpg(resized, quality: 70);
  return Uint8List.fromList(jpg);
}
