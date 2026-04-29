class SelectedItemModel {
  final String name;
  final double weight; // in kg
  final int quantity;
  final bool essential;
  final String? categoryName; // For display
  final bool isCustom; // true if custom item, false if AI item

  SelectedItemModel({
    required this.name,
    required this.weight,
    this.quantity = 1,
    this.essential = false,
    this.categoryName,
    this.isCustom = false,
  });

  double get totalWeight => weight * quantity;

  SelectedItemModel copyWith({
    String? name,
    double? weight,
    int? quantity,
    bool? essential,
    String? categoryName,
    bool? isCustom,
  }) {
    return SelectedItemModel(
      name: name ?? this.name,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      essential: essential ?? this.essential,
      categoryName: categoryName ?? this.categoryName,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

