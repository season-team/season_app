class BannerModel {
  final int id;
  final String image;
  final String? link;
  final String? route;
  final String? routeType;
  final Map<String, dynamic>? routeParams;
  final String language;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  BannerModel({
    required this.id,
    required this.image,
    this.link,
    this.route,
    this.routeType,
    this.routeParams,
    required this.language,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      link: json['link'],
      route: json['route'],
      routeType: json['route_type'],
      routeParams: json['route_params'] != null
          ? Map<String, dynamic>.from(json['route_params'] as Map)
          : null,
      language: json['language'] ?? 'ar',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'link': link,
      'route': route,
      'route_type': routeType,
      'route_params': routeParams,
      'language': language,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
