class Officer {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? sector;
  final String? officerStatus;

  Officer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.sector,
    this.officerStatus,
  });

  factory Officer.fromJson(Map<String, dynamic> json) {
    return Officer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      sector: json['sector'] as String?,
      officerStatus: json['officer_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'sector': sector,
      'officer_status': officerStatus,
    };
  }
}
