class MedicalRecord {
  final String id;
  final String distinguishingMarks;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> backgroundDiseases;
  final List<String> currentMedications;
  final String notes;
  final DateTime? updatedAt;

  MedicalRecord({
    required this.id,
    this.distinguishingMarks = '',
    this.bloodGroup = '',
    this.allergies = const [],
    this.backgroundDiseases = const [],
    this.currentMedications = const [],
    this.notes = '',
    this.updatedAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] ?? '',
      distinguishingMarks: json['distinguishingMarks'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      allergies: List<String>.from(json['allergies'] ?? []),
      backgroundDiseases: List<String>.from(json['backgroundDiseases'] ?? []),
      currentMedications: List<String>.from(json['currentMedications'] ?? []),
      notes: json['notes'] ?? '',
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'distinguishingMarks': distinguishingMarks,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'backgroundDiseases': backgroundDiseases,
      'currentMedications': currentMedications,
      'notes': notes,
    };
  }
}
