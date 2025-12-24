// lib/models/medicine_type.dart

class MedicineType {
  final int id;
  final String ma;
  final String tenloaithuoc; // Tên loại thuốc

  MedicineType({
    required this.id,
    required this.ma,
    required this.tenloaithuoc,
  });

  factory MedicineType.fromJson(Map<String, dynamic> json) {
    return MedicineType(
      id: json['id'] as int,
      ma: json['ma'] ?? '',
      tenloaithuoc: json['tenloaithuoc'] ?? '',
    );
  }
}