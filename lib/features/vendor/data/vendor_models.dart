class ServiceTypeModel {
  final int id;
  final String name;
  final bool isActive;

  ServiceTypeModel({required this.id, required this.name, required this.isActive});

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) => ServiceTypeModel(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: (json['is_active'] as bool?) ?? true,
      );
}

class CountryModel {
  final int id;
  final String name;
  final String code;

  CountryModel({required this.id, required this.name, required this.code});

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String,
      );
}

class VendorServiceSummary {
  final int id;
  final String name;
  final String status;

  VendorServiceSummary({required this.id, required this.name, required this.status});

  factory VendorServiceSummary.fromJson(Map<String, dynamic> json) => VendorServiceSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        status: json['status']?.toString() ?? '',
      );
}

class VendorServiceCountry {
  final int id;
  final String nameEn;
  final String nameAr;
  final String code;

  VendorServiceCountry({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.code,
  });

  factory VendorServiceCountry.fromJson(Map<String, dynamic> json) => VendorServiceCountry(
        id: json['id'] as int,
        nameEn: json['name_en']?.toString() ?? '',
        nameAr: json['name_ar']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
      );
}

class PublicVendorService {
  final int id;
  final String serviceType;
  final String name;
  final String description;
  final String contactNumber;
  final String address;
  final String latitude;
  final String longitude;
  final List<String> images;
  final String status;

  PublicVendorService({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.description,
    required this.contactNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.status,
  });

  factory PublicVendorService.fromJson(Map<String, dynamic> json) => PublicVendorService(
        id: json['id'] as int,
        serviceType: json['service_type']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        contactNumber: json['contact_number']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        latitude: json['latitude']?.toString() ?? '',
        longitude: json['longitude']?.toString() ?? '',
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        status: json['status']?.toString() ?? '',
      );
}

class VendorServiceDetails {
  final int id;
  final String serviceType;
  final String name;
  final String description;
  final String contactNumber;
  final String address;
  final String latitude;
  final String longitude;
  final VendorServiceCountry? country;
  final String? commercialRegisterUrl;
  final List<String> images;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  VendorServiceDetails({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.description,
    required this.contactNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.country,
    this.commercialRegisterUrl,
    required this.images,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory VendorServiceDetails.fromJson(Map<String, dynamic> json) => VendorServiceDetails(
        id: json['id'] as int,
        serviceType: json['service_type']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        contactNumber: json['contact_number']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        latitude: json['latitude']?.toString() ?? '',
        longitude: json['longitude']?.toString() ?? '',
        country: json['country'] != null
            ? VendorServiceCountry.fromJson(json['country'] as Map<String, dynamic>)
            : null,
        commercialRegisterUrl: json['commercial_register']?.toString(),
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        status: json['status']?.toString() ?? '',
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}
