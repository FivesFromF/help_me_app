class ContactInfo {
  final String name;
  final String relationship;
  final String phone;
  final String backupPhone;
  final String email;

  ContactInfo({
    required this.name,
    this.relationship = '',
    this.phone = '',
    this.backupPhone = '',
    this.email = '',
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'] ?? '',
      backupPhone: json['backupPhone'] ?? json['backup_phone'] ?? json['email'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'backupPhone': backupPhone,
      'email': email,
    };
  }
}
