class AIItemModel {
  final String name;
  final double weight; // in kg
  final int weightGrams; // weight in grams (for reference)

  AIItemModel({
    required this.name,
    required this.weight,
    required this.weightGrams,
  });

  factory AIItemModel.fromJson(Map<String, dynamic> json) {
    return AIItemModel(
      name: json['name'] as String? ?? '',
      weight: _parseDouble(json['weight']),
      weightGrams: json['weight_grams'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'weight_grams': weightGrams,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

