class CategoryModel {
  final int id;
  final String name;
  final String? icon;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString(),
        isActive: (json['is_active'] as bool?) ?? true,
      );
}
