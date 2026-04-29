class BagCategoryModel {
  final int id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? icon;
  final String? iconColor;

  BagCategoryModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.icon,
    this.iconColor,
  });

  factory BagCategoryModel.fromJson(Map<String, dynamic> json) {
    return BagCategoryModel(
      id: json['category_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? json['name_ar'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      icon: json['icon'],
      iconColor: json['icon_color'],
    );
  }
  
  /// Get localized name based on language
  String getName(String languageCode) {
    if (languageCode == 'ar' && nameAr != null) return nameAr!;
    if (languageCode == 'en' && nameEn != null) return nameEn!;
    return name;
  }
}

