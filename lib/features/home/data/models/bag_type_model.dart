class BagTypeModel {
  final int id;
  final String name;
  final String? description;
  final double defaultMaxWeight;
  final bool isActive;

  BagTypeModel({
    required this.id,
    required this.name,
    this.description,
    required this.defaultMaxWeight,
    required this.isActive,
  });

  factory BagTypeModel.fromJson(Map<String, dynamic> json) {
    return BagTypeModel(
      id: json['bag_type_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      defaultMaxWeight: _parseDouble(json['default_max_weight']),
      isActive: json['is_active'] ?? true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

