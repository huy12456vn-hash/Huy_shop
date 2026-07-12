import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Uint8List? imageBytes;
  String? imageUrl;
  bool isUploadingImage = false; // cờ khóa nút Lưu trong lúc đang upload ảnh

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showProductDialog([Map<String, dynamic>? product]) async {
    final nameController = TextEditingController(text: product?['name']?.toString() ?? '');
    final priceController = TextEditingController(
      text: product != null ? product['price']?.toString() ?? '' : '',
    );
    final descriptionController = TextEditingController(text: product?['description']?.toString() ?? '');

    // Reset đầy đủ mỗi lần mở dialog, tránh dính dữ liệu ảnh của lần trước
    imageBytes = null;
    imageUrl = product?['image'];
    isUploadingImage = false;

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
                      decoration: const InputDecoration(
                        labelText: 'Giá sản phẩm',
                        border: OutlineInputBorder(),
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
                                : (imageUrl != null && imageUrl!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageUrl!,
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
                              icon: isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.image),
                              label: Text(isUploadingImage ? "Đang tải ảnh lên..." : "Import Image"),
                              onPressed: isUploadingImage
                                  ? null
                                  : () async {
                                      await pickImage(() {
                                        setStateDialog(() {});
                                      });
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
                    // reset khi hủy để không dính dữ liệu ảnh cho lần mở dialog sau
                    imageBytes = null;
                    imageUrl = null;
                    isUploadingImage = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isUploadingImage
                      ? null // khóa nút Lưu khi ảnh chưa upload xong
                      : () async {
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text.trim());
                          final description = descriptionController.text.trim();

                          if (name.isEmpty || price == null || selectedCategoryId == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập đủ thông tin bắt buộc.')),
                            );
                            return;
                          }

                          final categoryDoc = await _categoriesRef.doc(selectedCategoryId).get();
                          final categoryName = categoryDoc.exists
                              ? (categoryDoc.data()?['name']?.toString() ?? '')
                              : '';

                          if (product == null) {
                            await _productsRef.add({
                              'name': name,
                              'price': price,
                              'description': description,
                              'image': imageUrl ?? '',
                              'categoryId': selectedCategoryId,
                              'categoryName': categoryName,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          } else {
                            await _productsRef.doc(productId).update({
                              'name': name,
                              'price': price,
                              'description': description,
                              'image': imageUrl ?? '',
                              'categoryId': selectedCategoryId,
                              'categoryName': categoryName,
                            });
                          }

                          imageBytes = null;
                          imageUrl = null;

                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                  child: isUploadingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm!')));
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

  Future<void> pickImage(VoidCallback refresh) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null) {
        debugPrint("Không chọn file");
        return;
      }

      final file = result.files.first;
      debugPrint("Tên file: ${file.name}");
      debugPrint("Bytes: ${file.bytes?.length}");

      imageBytes = file.bytes;

      if (imageBytes == null) {
        debugPrint("imageBytes = null");
        return;
      }

      // Bật cờ đang upload + hiện preview ngay
      isUploadingImage = true;
      refresh();

      final ref = FirebaseStorage.instance
          .ref()
          .child("products/${DateTime.now().millisecondsSinceEpoch}_${file.name}");

      final task = await ref.putData(imageBytes!);
      debugPrint("State: ${task.state}");

      imageUrl = await ref.getDownloadURL();
      debugPrint("Upload OK: $imageUrl");
    } catch (e) {
      debugPrint("========== ERROR UPLOAD ẢNH ==========");
      debugPrint(e.toString());
      debugPrint("=======================================");
    } finally {
      // Luôn tắt cờ upload dù thành công hay lỗi, để không khóa nút Lưu mãi
      isUploadingImage = false;
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              stream: _productsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (streamSnapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
                }
                if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có sản phẩm nào.'));
                }

                final products = streamSnapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  return <String, dynamic>{...data, 'id': doc.id};
                }).toList();

                final query = _searchController.text.trim().toLowerCase();
                final filteredProducts = products.where((product) {
                  final name = (product['name']?.toString() ?? '').toLowerCase();
                  final category = (product['categoryName']?.toString() ?? '').toLowerCase();
                  final description = (product['description']?.toString() ?? '').toLowerCase();
                  return query.isEmpty || name.contains(query) || category.contains(query) || description.contains(query);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('Không tìm thấy sản phẩm phù hợp.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final categoryName = product['categoryName']?.toString() ?? 'Chưa có danh mục';
                    final description = product['description']?.toString() ?? '';
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
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name']?.toString() ?? 'Không tên',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        '${price.toString()} ₫',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(categoryName, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (description.isNotEmpty)
                                  Text(
                                    description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black87, height: 1.4),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildInfoChip(Icons.star_border, 'Mới'),
                                          _buildInfoChip(Icons.local_shipping_outlined, 'Giao hàng'),
                                          _buildInfoChip(Icons.favorite_border, 'Hot'),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      onPressed: () => _showProductDialog(product),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Xác nhận xóa'),
                                          content: const Text('Bạn có chắc muốn xóa sản phẩm này?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteProduct(product['id'].toString());
                                              },
                                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
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