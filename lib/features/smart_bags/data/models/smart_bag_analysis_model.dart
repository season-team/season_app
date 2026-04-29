class MissingItem {
  final String id;
  final String name;
  final double weight;
  final String reason;
  final String priority; // high, medium, low
  final String category;

  MissingItem({
    required this.id,
    required this.name,
    required this.weight,
    required this.reason,
    required this.priority,
    required this.category,
  });

  factory MissingItem.fromJson(Map<String, dynamic> json) {
    return MissingItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      weight: _parseDouble(json['weight']),
      reason: json['reason'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String? ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ExtraItem {
  final String id;
  final String name;
  final String reason;
  final double weightSaved;

  ExtraItem({
    required this.id,
    required this.name,
    required this.reason,
    required this.weightSaved,
  });

  factory ExtraItem.fromJson(Map<String, dynamic> json) {
    return ExtraItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      weightSaved: _parseDouble(json['weight_saved']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class WeightOptimization {
  final double currentWeight;
  final double suggestedWeight;
  final double weightSaved;
  final String impactLevel; // high, medium, low
  final double percentageSaved;

  WeightOptimization({
    required this.currentWeight,
    required this.suggestedWeight,
    required this.weightSaved,
    required this.impactLevel,
    required this.percentageSaved,
  });

  factory WeightOptimization.fromJson(Map<String, dynamic> json) {
    return WeightOptimization(
      currentWeight: _parseDouble(json['current_weight']),
      suggestedWeight: _parseDouble(json['suggested_weight']),
      weightSaved: _parseDouble(json['weight_saved']),
      impactLevel: json['impact_level'] as String? ?? 'medium',
      percentageSaved: _parseDouble(json['percentage_saved']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class SmartAlert {
  final String alertId;
  final String timeRemaining;
  final String message;
  final String severity; // high, medium, low

  SmartAlert({
    required this.alertId,
    required this.timeRemaining,
    required this.message,
    required this.severity,
  });

  factory SmartAlert.fromJson(Map<String, dynamic> json) {
    return SmartAlert(
      alertId: json['alert_id'] as String? ?? '',
      timeRemaining: json['time_remaining'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
    );
  }
}

class SmartBagAnalysisModel {
  final String analysisId;
  final int bagId;
  final List<MissingItem> missingItems;
  final List<ExtraItem> extraItems;
  final WeightOptimization? weightOptimization;
  final List<Map<String, dynamic>> additionalSuggestions;
  final SmartAlert? smartAlert;
  final double confidenceScore; // 0-1
  final int processingTimeMs;
  final String aiModel;
  final DateTime? createdAt;

  SmartBagAnalysisModel({
    required this.analysisId,
    required this.bagId,
    required this.missingItems,
    required this.extraItems,
    this.weightOptimization,
    required this.additionalSuggestions,
    this.smartAlert,
    required this.confidenceScore,
    required this.processingTimeMs,
    required this.aiModel,
    this.createdAt,
  });

  factory SmartBagAnalysisModel.fromJson(Map<String, dynamic> json) {
    return SmartBagAnalysisModel(
      analysisId: json['analysis_id'] as String? ?? '',
      bagId: json['bag_id'] as int? ?? 0,
      missingItems: (json['missing_items'] as List<dynamic>?)
              ?.map((item) => MissingItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      extraItems: (json['extra_items'] as List<dynamic>?)
              ?.map((item) => ExtraItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      weightOptimization: json['weight_optimization'] != null
          ? WeightOptimization.fromJson(
              json['weight_optimization'] as Map<String, dynamic>)
          : null,
      additionalSuggestions:
          (json['additional_suggestions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      smartAlert: json['smart_alert'] != null
          ? SmartAlert.fromJson(json['smart_alert'] as Map<String, dynamic>)
          : null,
      confidenceScore: _parseDouble(json['confidence_score']),
      processingTimeMs: json['processing_time_ms'] as int? ?? 0,
      aiModel: json['ai_model'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

