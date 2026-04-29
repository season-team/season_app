class BagItemModel {
  final int id;
  final String name;
  final double defaultWeight;
  final String weightUnit;
  final int categoryId;
  final String? icon;
  final String? description;

  BagItemModel({
    required this.id,
    required this.name,
    required this.defaultWeight,
    required this.weightUnit,
    required this.categoryId,
    this.icon,
    this.description,
  });

  factory BagItemModel.fromJson(Map<String, dynamic> json) {
    return BagItemModel(
      id: json['item_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      defaultWeight: _parseDouble(json['default_weight']),
      weightUnit: (json['weight_unit'] ?? '').toString(),
      categoryId: json['category_id'] ?? 0,
      icon: json['icon'],
      description: json['description'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

