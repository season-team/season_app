class SmartBagItemModel {
  final int id;
  final int bagId;
  final String name;
  final double weight; // kg
  final String category; // ملابس، أحذية، إلكترونيات، أدوية، مستندات، أخرى
  final bool essential;
  final bool packed;
  final int quantity;
  final String? notes;

  SmartBagItemModel({
    required this.id,
    required this.bagId,
    required this.name,
    required this.weight,
    required this.category,
    required this.essential,
    required this.packed,
    required this.quantity,
    this.notes,
  });

  factory SmartBagItemModel.fromJson(Map<String, dynamic> json) {
    return SmartBagItemModel(
      id: json['id'] as int,
      bagId: json['bag_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      weight: _parseDouble(json['weight']),
      category: json['category'] as String? ?? '',
      essential: json['essential'] as bool? ?? false,
      packed: json['packed'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bag_id': bagId,
      'name': name,
      'weight': weight,
      'category': category,
      'essential': essential,
      'packed': packed,
      'quantity': quantity,
      'notes': notes,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

