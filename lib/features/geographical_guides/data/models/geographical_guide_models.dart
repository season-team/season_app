class GeographicalCategory {
  final int id;
  final String nameAr;
  final String nameEn;
  final String name; // Localized name based on Accept-Language
  final String? icon;
  final bool isActive;
  final List<GeographicalSubCategory>? subCategories;

  GeographicalCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.name,
    this.icon,
    required this.isActive,
    this.subCategories,
  });

  factory GeographicalCategory.fromJson(Map<String, dynamic> json) =>
      GeographicalCategory(
        id: json['id'] as int,
        nameAr: json['name_ar']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        name: json['name']?.toString() ?? json['name_ar']?.toString() ?? '',
        icon: json['icon']?.toString(),
        isActive: (json['is_active'] as bool?) ?? true,
        subCategories: json['sub_categories'] != null
            ? (json['sub_categories'] as List)
                .map((e) => GeographicalSubCategory.fromJson(
                    e as Map<String, dynamic>))
                .toList()
            : null,
      );
}

class GeographicalSubCategory {
  final int id;
  final int geographicalCategoryId;
  final String nameAr;
  final String nameEn;
  final String name; // Localized name
  final bool isActive;

  GeographicalSubCategory({
    required this.id,
    required this.geographicalCategoryId,
    required this.nameAr,
    required this.nameEn,
    required this.name,
    required this.isActive,
  });

  factory GeographicalSubCategory.fromJson(Map<String, dynamic> json) =>
      GeographicalSubCategory(
        id: json['id'] as int,
        geographicalCategoryId:
            json['geographical_category_id'] as int? ?? 0,
        nameAr: json['name_ar']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        name: json['name']?.toString() ?? json['name_ar']?.toString() ?? '',
        isActive: (json['is_active'] as bool?) ?? true,
      );
}

class City {
  final int id;
  final String nameAr;
  final String nameEn;
  final String name; // Localized name
  final int countryId;

  City({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.name,
    required this.countryId,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as int,
        nameAr: json['name_ar']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        name: json['name']?.toString() ?? json['name_ar']?.toString() ?? '',
        countryId: json['country_id'] as int? ?? 0,
      );
}

class Country {
  final int id;
  final String nameAr;
  final String nameEn;
  final String name; // Localized name
  final String code;

  Country({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.name,
    required this.code,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id'] as int,
        nameAr: json['name_ar']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        name: json['name']?.toString() ?? json['name_ar']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
      );
}

class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
      );
}

class GeographicalGuide {
  final int id;
  final User? user;
  final GeographicalCategory category;
  final GeographicalSubCategory? subCategory;
  final String serviceName;
  final String? description;
  final String? phone1;
  final String? phone2;
  final Country country;
  final City city;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String? website;
  final String? commercialRegister;
  final String? establishmentNumber;
  final bool isActive;
  final String status; // Localized status
  final String? createdAt;
  final String? updatedAt;

  GeographicalGuide({
    required this.id,
    this.user,
    required this.category,
    this.subCategory,
    required this.serviceName,
    this.description,
    this.phone1,
    this.phone2,
    required this.country,
    required this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.website,
    this.commercialRegister,
    this.establishmentNumber,
    required this.isActive,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory GeographicalGuide.fromJson(Map<String, dynamic> json) {
    // Handle null category
    if (json['category'] == null) {
      throw Exception('Category is required but was null');
    }
    final categoryData = json['category'] as Map<String, dynamic>?;
    if (categoryData == null) {
      throw Exception('Category data is invalid');
    }

    // Handle null country
    if (json['country'] == null) {
      throw Exception('Country is required but was null');
    }
    final countryData = json['country'] as Map<String, dynamic>?;
    if (countryData == null) {
      throw Exception('Country data is invalid');
    }

    // Handle null city
    if (json['city'] == null) {
      throw Exception('City is required but was null');
    }
    final cityData = json['city'] as Map<String, dynamic>?;
    if (cityData == null) {
      throw Exception('City data is invalid');
    }

    return GeographicalGuide(
      id: json['id'] as int,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      category: GeographicalCategory.fromJson(categoryData),
      subCategory: json['sub_category'] != null
          ? GeographicalSubCategory.fromJson(
              json['sub_category'] as Map<String, dynamic>)
          : null,
      serviceName: json['service_name']?.toString() ?? '',
      description: json['description']?.toString(),
      phone1: json['phone_1']?.toString(),
      phone2: json['phone_2']?.toString(),
      country: Country.fromJson(countryData),
      city: City.fromJson(cityData),
      address: json['address']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      website: json['website']?.toString(),
      commercialRegister: json['commercial_register']?.toString(),
      establishmentNumber: json['establishment_number']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

