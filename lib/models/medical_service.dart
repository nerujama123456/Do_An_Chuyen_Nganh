// lib/models/medical_service.dart

class MedicalService {
  final int id;
  final String ma;
  final String tendichvu; // Tên dịch vụ
  final int giavnd;       // Giá

  MedicalService({
    required this.id,
    required this.ma,
    required this.tendichvu,
    required this.giavnd,
  });

  factory MedicalService.fromJson(Map<String, dynamic> json) {
    return MedicalService(
      id: json['id'] as int,
      ma: json['ma'] ?? '',
      tendichvu: json['tendichvu'] ?? '',
      giavnd: json['giavnd'] is int ? json['giavnd'] : (int.tryParse(json['giavnd'].toString()) ?? 0),
    );
  }
}