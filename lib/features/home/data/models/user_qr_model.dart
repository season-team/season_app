class UserQrModel {
  final int id;
  final String name;
  final int coins;
  final String? photoUrl;
  final String qrCodeUrl;

  const UserQrModel({
    required this.id,
    required this.name,
    required this.coins,
    this.photoUrl,
    required this.qrCodeUrl,
  });

  factory UserQrModel.fromJson(Map<String, dynamic> json) {
    return UserQrModel(
      id: json['id'] as int,
      name: json['name'] as String,
      coins: json['coins'] as int,
      photoUrl: json['photo_url'] as String?,
      qrCodeUrl: json['qr_code_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coins': coins,
      'photo_url': photoUrl,
      'qr_code_url': qrCodeUrl,
    };
  }
}
