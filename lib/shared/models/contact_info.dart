class ContactInfo {
  final String name;
  final String relationship;
  final String phone;
  final String email;

  ContactInfo({
    required this.name,
    this.relationship = '',
    this.phone = '',
    this.email = '',
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
    };
  }
}
