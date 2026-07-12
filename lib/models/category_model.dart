class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(id: id, name: data['name'] ?? '');
  }
}
