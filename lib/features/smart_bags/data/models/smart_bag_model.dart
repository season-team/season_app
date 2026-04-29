class SmartBagModel {
  final int id;
  final int userId;
  final String name;
  final String tripType; // عمل، سياحة، عائلية، علاج
  final int duration; // days
  final String destination;
  final DateTime departureDate;
  final double maxWeight; // kg
  final double totalWeight; // kg
  final double weightPercentage;
  final double remainingWeight; // kg
  final bool isOverweight;
  final int daysUntilDeparture;
  final String status; // draft, in_progress, completed, cancelled
  final Map<String, dynamic>? preferences;
  final bool isAnalyzed;
  final DateTime? lastAnalyzedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SmartBagModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.tripType,
    required this.duration,
    required this.destination,
    required this.departureDate,
    required this.maxWeight,
    required this.totalWeight,
    required this.weightPercentage,
    required this.remainingWeight,
    required this.isOverweight,
    required this.daysUntilDeparture,
    required this.status,
    this.preferences,
    required this.isAnalyzed,
    this.lastAnalyzedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SmartBagModel.fromJson(Map<String, dynamic> json) {
    return SmartBagModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      tripType: json['trip_type'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      destination: json['destination'] as String? ?? '',
      departureDate: json['departure_date'] != null
          ? DateTime.parse(json['departure_date'] as String)
          : DateTime.now(),
      maxWeight: _parseDouble(json['max_weight']),
      totalWeight: _parseDouble(json['total_weight']),
      weightPercentage: _parseDouble(json['weight_percentage']),
      remainingWeight: _parseDouble(json['remaining_weight']),
      isOverweight: json['is_overweight'] as bool? ?? false,
      daysUntilDeparture: json['days_until_departure'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      preferences: json['preferences'] as Map<String, dynamic>?,
      isAnalyzed: json['is_analyzed'] as bool? ?? false,
      lastAnalyzedAt: json['last_analyzed_at'] != null
          ? DateTime.parse(json['last_analyzed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'trip_type': tripType,
      'duration': duration,
      'destination': destination,
      'departure_date': departureDate.toIso8601String().split('T')[0],
      'max_weight': maxWeight,
      'total_weight': totalWeight,
      'weight_percentage': weightPercentage,
      'remaining_weight': remainingWeight,
      'is_overweight': isOverweight,
      'days_until_departure': daysUntilDeparture,
      'status': status,
      'preferences': preferences,
      'is_analyzed': isAnalyzed,
      'last_analyzed_at': lastAnalyzedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

