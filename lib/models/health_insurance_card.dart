// lib/models/health_insurance_card.dart

class HealthInsuranceCard {
  final int id;
  final String mabhyt;
  final int patient_id;
  final String tenbenhnhan; // Từ JOIN
  final String noidangkykham;
  final String ngaygiatrisudung;
  final String maso;
  final String ngaycap;
  final String noicap;

  HealthInsuranceCard({
    required this.id,
    required this.mabhyt,
    required this.patient_id,
    required this.tenbenhnhan,
    required this.noidangkykham,
    required this.ngaygiatrisudung,
    required this.maso,
    required this.ngaycap,
    required this.noicap,
  });

  factory HealthInsuranceCard.fromJson(Map<String, dynamic> json) {
    return HealthInsuranceCard(
      id: json['id'] as int,
      mabhyt: json['mabhyt'] ?? '',
      patient_id: json['patient_id'] as int? ?? 0,
      tenbenhnhan: json['tenbenhnhan'] ?? 'N/A', // Từ JOIN
      noidangkykham: json['noidangkykham'] ?? '',
      ngaygiatrisudung: json['ngaygiatrisudung'] ?? '',
      maso: json['maso'] ?? '',
      ngaycap: json['ngaycap'] ?? '',
      noicap: json['noicap'] ?? '',
    );
  }
}