import 'package:flutter/foundation.dart';

class BagItemInBagModel {
  final int? itemId;
  final String name;
  final String? category;
  final int? itemCategoryId;
  final int quantity;
  final double weightPerItem;
  final double totalWeight;
  final String weightUnit;
  final bool isCustom;
  final String? customItemName;
  
  // Smart Bags API fields
  final bool? essential;
  final bool? packed;
  final String? notes;

  BagItemInBagModel({
    this.itemId,
    required this.name,
    this.category,
    this.itemCategoryId,
    required this.quantity,
    required this.weightPerItem,
    required this.totalWeight,
    required this.weightUnit,
    this.isCustom = false,
    this.customItemName,
    this.essential,
    this.packed,
    this.notes,
  });

  factory BagItemInBagModel.fromJson(Map<String, dynamic> json) {
    debugPrint('📦 Parsing bag item: $json');
    
    final isCustom = json['is_custom'] ?? false;
    final customItemName = json['custom_item_name']?.toString();
    
    // Support both legacy and Smart Bags API formats
    // Try weight first (Smart Bags format), then weight_per_item (legacy)
    double weightPerItem = _parseDouble(json['weight'] ?? json['weight_per_item']);
    final quantity = json['quantity'] as int? ?? 1;
    
    // Calculate total_weight if not provided
    double totalWeight = _parseDouble(json['total_weight']);
    if (totalWeight == 0 && weightPerItem > 0) {
      totalWeight = weightPerItem * quantity;
    }
    
    // If both are 0, this might be a backend issue - try to infer from other fields
    if (weightPerItem == 0 && totalWeight == 0) {
      // Backend might not be returning weight properly
      // We'll keep it as 0 but log it
      debugPrint('⚠️ Item weight is 0 - possible backend issue');
    }
    
    // Parse category from nested object or direct field
    String? category;
    int? itemCategoryId;
    if (json['category'] is Map<String, dynamic>) {
      final categoryData = json['category'] as Map<String, dynamic>;
      category = categoryData['name']?.toString() ?? categoryData['name_ar']?.toString();
      itemCategoryId = categoryData['id'] as int?;
    } else {
      category = json['category']?.toString() ?? json['category_en']?.toString();
      itemCategoryId = json['item_category_id'] as int?;
    }
    
    // Parse item name - try multiple fields
    // Skip "Unknown Item" as it's a backend placeholder
    String itemName = '';
    final rawName = json['name']?.toString().trim() ?? '';
    
    if (rawName.isNotEmpty && rawName.toLowerCase() != 'unknown item') {
      itemName = rawName;
    } else if (customItemName != null && customItemName.trim().isNotEmpty) {
      itemName = customItemName;
    } else if (json['item_name'] != null) {
      final itemNameValue = json['item_name'].toString().trim();
      if (itemNameValue.isNotEmpty && itemNameValue.toLowerCase() != 'unknown item') {
        itemName = itemNameValue;
      }
    }
    
    // If still empty, try to get from category or use a generic name
    if (itemName.isEmpty) {
      if (category != null && category.isNotEmpty) {
        itemName = '$category Item'; // Fallback: "Category Item"
      } else {
        itemName = 'Unnamed Item'; // Final fallback
      }
    }
    
    debugPrint('📦 Parsed item name: "$itemName" (raw: "$rawName")');
    
    return BagItemInBagModel(
      itemId: json['id'] as int? ?? json['item_id'] as int?,
      name: itemName,
      category: category,
      itemCategoryId: itemCategoryId,
      quantity: quantity,
      weightPerItem: weightPerItem,
      totalWeight: totalWeight,
      weightUnit: (json['weight_unit'] ?? 'kg').toString().toLowerCase(),
      isCustom: isCustom,
      customItemName: customItemName,
      essential: json['essential'] as bool? ?? false,
      packed: json['packed'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
