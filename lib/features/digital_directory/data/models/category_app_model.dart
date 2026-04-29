class CategoryAppModel {
  final int id;
  final String name;
  final String icon;
  final String url;
  final bool isActive;

  CategoryAppModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.url,
    required this.isActive,
  });

  factory CategoryAppModel.fromJson(Map<String, dynamic> json) => CategoryAppModel(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        isActive: (json['is_active'] as bool?) ?? true,
      );
}
