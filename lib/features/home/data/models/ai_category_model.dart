class AICategoryModel {
  final String name;

  AICategoryModel({
    required this.name,
  });

  factory AICategoryModel.fromJson(Map<String, dynamic> json) {
    return AICategoryModel(
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

