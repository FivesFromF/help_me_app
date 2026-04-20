import 'contact_info.dart';

class CitizenProfile {
  final String id;
  final String cognitoId;
  final String email;
  final String fullName;
  final String phone;
  final String avatarUrl;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String cccdNumber;
  final List<ContactInfo> emergencyContacts;

  CitizenProfile({
    required this.id,
    required this.cognitoId,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.avatarUrl = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.address = '',
    this.cccdNumber = '',
    this.emergencyContacts = const [],
  });

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    return CitizenProfile(
      id: json['id'] ?? '',
      cognitoId: json['cognitoId'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      cccdNumber: json['cccdNumber'] ?? '',
      emergencyContacts: (json['emergencyContacts'] as List?)
              ?.map((e) => ContactInfo.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cognitoId': cognitoId,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'cccdNumber': cccdNumber,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
    };
  }
}
