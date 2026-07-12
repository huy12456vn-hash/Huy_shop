import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CollectionReference<Map<String, dynamic>> _categories =
      FirebaseFirestore.instance.collection('categories');
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _showCategoryDialog([DocumentSnapshot? documentSnapshot]) async {
    final TextEditingController nameController = TextEditingController();
    if(documentSnapshot != null){
      nameController.text = documentSnapshot['name'];
    }
    await showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          title: Text(documentSnapshot == null ? 'Thêm Danh Mục' : 'Sửa Danh Mục'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Tên danh mục', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  if (documentSnapshot == null) {
                    // Create
                    await _categories.add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
                  } else {
                    // Update
                    await _categories.doc(documentSnapshot.id).update({'name': name});
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      }
    );
  }
  Future<void> _deleteCategory(String categoryId) async {
    await _categories.doc(categoryId).delete();
    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa danh mục thành công')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: Colors.blue,
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
                hintText: 'Tìm kiếm danh mục...',
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
              stream: _categories.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (streamSnapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
                }
                if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có danh mục nào.'));
                }

                final query = _searchController.text.trim().toLowerCase();
                final filteredDocs = streamSnapshot.data!.docs.where((doc) {
                  final name = (doc.data()['name']?.toString() ?? '').toLowerCase();
                  return query.isEmpty || name.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Không tìm thấy danh mục phù hợp.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final documentSnapshot = filteredDocs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.category, color: Colors.white),
                        ),
                        title: Text(documentSnapshot.data()['name']?.toString() ?? 'Không tên'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showCategoryDialog(documentSnapshot),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Xác nhận xóa'),
                                  content: const Text('Bạn có chắc muốn xóa danh mục này?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteCategory(documentSnapshot.id);
                                      },
                                      child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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