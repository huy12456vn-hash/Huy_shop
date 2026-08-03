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

  Uint8List? imageBytes; // original image selected for preview
  String? imageBase64; // base64 string to be stored in Firestore
  bool isProcessingImage = false; // resizing/encoding the image

  // Default size list applied to all products.
  // You can modify this list based on the products you sell.
  static const List<String> _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  // Selected sizes in the add/edit product dialog.
  List<String> selectedSizes = [];

  // Bulk creation of default sizes for older products is in progress.
  bool isBulkGeneratingSizes = false;

  // Safe size limit for a single Firestore string field (~1MB/document).
  // Base64 adds about 33% overhead, so the threshold is kept lower for safety.
  static const int _maxBase64Length = 700000; // ~700KB base64 (~500KB original image)

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

    // Fully reset each time the dialog opens
    imageBytes = null;
    imageBase64 = product?['image']?.toString();
    isProcessingImage = false;
    selectedSizes = List<String>.from(
      (product?['sizes'] as List?)?.map((e) => e.toString()) ?? const [],
    );

    String? selectedCategoryId = product?['categoryId']?.toString();
    final productId = product?['id']?.toString();

    final categoriesSnapshot = await _categoriesRef.get();
    final categoryItems = categoriesSnapshot.docs.map((doc) {
      final categoryData = doc.data();
      return DropdownMenuItem<String>(
        value: doc.id,
        child: Text(categoryData['name']?.toString() ?? 'Untitled'),
      );
    }).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ThousandsSeparatorInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Product Price',
                        border: OutlineInputBorder(),
                        suffixText: '\$',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categoryItems,
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sizes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSizes.map((size) {
                        final isSelected = selectedSizes.contains(size);
                        return FilterChip(
                          label: Text(size),
                          selected: isSelected,
                          selectedColor: Colors.green.shade100,
                          checkmarkColor: Colors.green,
                          onSelected: (value) {
                            setStateDialog(() {
                              if (value) {
                                selectedSizes.add(size);
                              } else {
                                selectedSizes.remove(size);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                                    ? "Processing image..."
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
                    selectedSizes = [];
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
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
                                  'Please enter all required information.',
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
                              'name_lowercase':name.toLowerCase(),
                              'price': price,
                              'description': description,
                              'image': imageBase64 ?? '',
                              'categoryId': selectedCategoryId,
                              'categoryName': categoryName,
                              'sizes': selectedSizes,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          } else {
                            await _productsRef.doc(productId).update({
                              'name': name,
                              'name_lowercase':name.toLowerCase(),
                              'price': price,
                              'description': description,
                              'image': imageBase64 ?? '',
                              'categoryId': selectedCategoryId,
                              'categoryName': categoryName,
                              'sizes': selectedSizes,
                            });
                          }

                          imageBytes = null;
                          imageBase64 = null;
                          selectedSizes = [];

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
                      : const Text('Save'),
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
    ).showSnackBar(const SnackBar(content: Text('Product deleted!')));
  }

  /// Scan all products in Firestore; any product without a `sizes` field
  /// (or with an empty one) will receive the default size list.
  Future<void> _generateDefaultSizesForExistingProducts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Default Sizes'),
        content: Text(
          'This will automatically add default sizes '
          '(${_availableSizes.join(', ')}) to ALL products that do not have sizes yet. '
          'Products that already have sizes will be kept unchanged. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agree'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isBulkGeneratingSizes = true);

    try {
      final snapshot = await _productsRef.get();

      // Firestore limits each batch to 500 writes, so chunking is needed if necessary.
      final docsNeedingSizes = snapshot.docs.where((doc) {
        final sizes = doc.data()['sizes'];
        final hasSizes = sizes is List && sizes.isNotEmpty;
        return !hasSizes;
      }).toList();

      int updatedCount = 0;
      for (var i = 0; i < docsNeedingSizes.length; i += 500) {
        final chunk = docsNeedingSizes.skip(i).take(500);
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {'sizes': _availableSizes});
          updatedCount++;
        }
        await batch.commit();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedCount > 0
                ? 'Default sizes were created for $updatedCount products.'
                : 'All products already have sizes, no update is needed.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error creating default sizes: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while creating sizes for the product.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isBulkGeneratingSizes = false);
    }
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

  Widget _buildSizeChip(String size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        size,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  /// Pick an image, resize it, and encode it to base64.
  /// [onError] reports errors (for example, when the image is still too large) via SnackBar.
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

      // Run directly on the main thread (not using compute/Isolate because
      // Isolate.spawn is not fully supported on Flutter Web and can cause issues).
      // The image is already constrained in size, so processing remains fast.
      // Give the UI one frame to render the loading state before processing the image.
      await Future.delayed(Duration.zero);
      final resizedBytes = _resizeAndEncodeJpg(originalBytes);

      if (resizedBytes == null) {
        onError('Unable to process this image. Please choose another one.');
        return;
      }

      final encoded = base64Encode(resizedBytes);

      if (encoded.length > _maxBase64Length) {
        onError(
          'The image is still too large after compression (${(encoded.length / 1024).toStringAsFixed(0)}KB). '
          'Please choose an image with a smaller resolution.',
        );
        return;
      }

      imageBytes = resizedBytes;
      imageBase64 = encoded;
    } catch (e) {
      debugPrint('Image processing error: $e');
      onError('An error occurred while processing the image.');
    } finally {
      isProcessingImage = false;
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Create default sizes for products without sizes',
            icon: isBulkGeneratingSizes
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.straighten),
            onPressed: isBulkGeneratingSizes
                ? null
                : _generateDefaultSizesForExistingProducts,
          ),
        ],
      ),
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
                hintText: 'Search products...',
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
                    child: Text('An error occurred while loading data.'),
                  );
                }
                if (!streamSnapshot.hasData ||
                    streamSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products yet.'));
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
                    child: Text('No matching products found.'),
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
                        'No category';
                    final description =
                        product['description']?.toString() ?? '';
                    final price = product['price'] ?? 0;
                    final productSizes =
                        (product['sizes'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        const <String>[];

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
                                            'Untitled',
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
                                        '\$${_formatPriceForDisplay(price)}',
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
                                if (productSizes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: productSizes
                                        .map(_buildSizeChip)
                                        .toList(),
                                  ),
                                ],
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
                                            'New',
                                          ),
                                          _buildInfoChip(
                                            Icons.local_shipping_outlined,
                                            'Shipping',
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
                                          title: const Text('Confirm Delete'),
                                          content: const Text(
                                            'Are you sure you want to delete this product?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteProduct(
                                                  product['id'].toString(),
                                                );
                                              },
                                              child: const Text(
                                                'Delete',
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

/// Insert thousand separators while the user types numbers, for example
/// typing "11000000" will display as "11.000.000".
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

    final formatted = _formatDigitsWithCommas(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Insert a comma every 3 digits from the right, for example "11000000" -> "11,000,000".
String _formatDigitsWithCommas(String digitsOnly) {
  final buffer = StringBuffer();
  for (int i = 0; i < digitsOnly.length; i++) {
    final posFromRight = digitsOnly.length - i;
    buffer.write(digitsOnly[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

/// Format the 'price' value from Firestore (num) as a USD-style string
/// so it is displayed directly in the input field when editing a product.
String _formatPriceForDisplay(dynamic priceValue) {
  if (priceValue == null) return '';
  final priceNum = priceValue is num
      ? priceValue
      : num.tryParse(priceValue.toString());
  if (priceNum == null) return '';
  final usdAmount = priceNum / 26300;
  final cents = (usdAmount * 100).round();
  final whole = cents ~/ 100;
  final fraction = (cents % 100).abs().toString().padLeft(2, '0');
  final digits = whole.toString();
  return _formatDigitsWithCommas(digits) + '.$fraction';
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