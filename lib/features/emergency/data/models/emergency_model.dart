class EmergencyModel {
  final int id;
  final String fire;
  final String police;
  final String ambulance;
  final String embassy;

  EmergencyModel({
    required this.id,
    required this.fire,
    required this.police,
    required this.ambulance,
    required this.embassy,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['id'] ?? 0,
      fire: json['fire'] ?? '',
      police: json['police'] ?? '',
      ambulance: json['ambulance'] ?? '',
      embassy: json['embassy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fire': fire,
      'police': police,
      'ambulance': ambulance,
      'embassy': embassy,
    };
  }
}
