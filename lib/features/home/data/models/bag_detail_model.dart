import 'package:season_app/features/home/data/models/bag_item_in_bag_model.dart';

class BagReminder {
  final String? date;
  final String? time;

  BagReminder({this.date, this.time});

  factory BagReminder.fromJson(Map<String, dynamic>? json) {
    if (json == null) return BagReminder();
    return BagReminder(
      date: json['date']?.toString(),
      time: json['time']?.toString(),
    );
  }
}

class BagDetailModel {
  final int bagId;
  final String bagName;
  final int bagType;
  final int bagTypeId;
  final double currentWeight;
  final double maxWeight;
  final String weightUnit;
  final double weightPercentage;
  final List<BagItemInBagModel> items;
  final bool isEmpty;
  final BagReminder? reminder;
  final String status;
  final bool isReady;
  
  // Smart Bags API fields
  final String? tripType; // عمل، سياحة، عائلية، علاج
  final int? duration; // days
  final String? destination;
  final DateTime? departureDate;
  final double? remainingWeight;
  final bool? isOverweight;
  final int? daysUntilDeparture;
  final Map<String, dynamic>? preferences;
  final bool? isAnalyzed;
  final DateTime? lastAnalyzedAt;
  final int? itemsCount;

  BagDetailModel({
    required this.bagId,
    required this.bagName,
    required this.bagType,
    required this.bagTypeId,
    required this.currentWeight,
    required this.maxWeight,
    required this.weightUnit,
    required this.weightPercentage,
    required this.items,
    required this.isEmpty,
    this.reminder,
    required this.status,
    required this.isReady,
    this.tripType,
    this.duration,
    this.destination,
    this.departureDate,
    this.remainingWeight,
    this.isOverweight,
    this.daysUntilDeparture,
    this.preferences,
    this.isAnalyzed,
    this.lastAnalyzedAt,
    this.itemsCount,
  });

  factory BagDetailModel.fromJson(Map<String, dynamic> json) {
    // Support both legacy API and Smart Bags API
    final isSmartBag = json['id'] != null || json['trip_type'] != null;
    
    if (isSmartBag) {
      // Smart Bags API format
      return BagDetailModel(
        bagId: json['id'] as int? ?? json['bag_id'] as int? ?? 0,
        bagName: json['name'] as String? ?? json['bag_name'] as String? ?? '',
        bagType: json['id'] as int? ?? json['bag_id'] as int? ?? 0, // Use bag id as bagType for Smart Bags
        bagTypeId: json['id'] as int? ?? json['bag_id'] as int? ?? 0, // Use bag id as bagTypeId for Smart Bags
        currentWeight: _parseDouble(json['total_weight'] ?? json['current_weight']),
        maxWeight: _parseDouble(json['max_weight']),
        weightUnit: 'kg',
        weightPercentage: _parseDouble(json['weight_percentage']),
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => BagItemInBagModel.fromJson(item))
                .toList() ??
            [],
        isEmpty: (json['items'] as List<dynamic>?)?.isEmpty ?? true,
        reminder: null, // Smart Bags uses departure_date instead
        status: json['status'] as String? ?? 'draft',
        isReady: json['status'] == 'completed' || json['status'] == 'in_progress',
        tripType: json['trip_type'] as String?,
        duration: json['duration'] as int?,
        destination: json['destination'] as String?,
        departureDate: json['departure_date'] != null
            ? DateTime.tryParse(json['departure_date'] as String)
            : null,
        remainingWeight: _parseDouble(json['remaining_weight']),
        isOverweight: json['is_overweight'] as bool? ?? false,
        daysUntilDeparture: json['days_until_departure'] as int?,
        preferences: _parsePreferences(json['preferences']),
        isAnalyzed: json['is_analyzed'] as bool? ?? false,
        lastAnalyzedAt: json['last_analyzed_at'] != null
            ? DateTime.tryParse(json['last_analyzed_at'] as String)
            : null,
        itemsCount: json['items_count'] as int?,
      );
    } else {
      // Legacy API format
      return BagDetailModel(
        bagId: json['bag_id'] ?? 0,
        bagName: json['bag_name'] ?? '',
        bagType: json['bag_type'] ?? 0,
        bagTypeId: json['bag_type_id'] ?? 0,
        currentWeight: _parseDouble(json['current_weight']),
        maxWeight: _parseDouble(json['max_weight']),
        weightUnit: json['weight_unit'] ?? 'kg',
        weightPercentage: _parseDouble(json['weight_percentage']),
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => BagItemInBagModel.fromJson(item))
                .toList() ??
            [],
        isEmpty: json['is_empty'] ?? true,
        reminder: json['reminder'] != null
            ? BagReminder.fromJson(json['reminder'] as Map<String, dynamic>)
            : null,
        status: json['status']?.toString() ?? 'not_ready',
        isReady: json['is_ready'] ?? false,
      );
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Parse preferences field - handles both Map and List (empty array)
  static Map<String, dynamic>? _parsePreferences(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is List) {
      // If it's an empty list, return null
      // If it's a non-empty list, try to convert first item to map
      if (value.isEmpty) return null;
      if (value.first is Map<String, dynamic>) {
        return value.first as Map<String, dynamic>;
      }
      return null;
    }
    return null;
  }
}

