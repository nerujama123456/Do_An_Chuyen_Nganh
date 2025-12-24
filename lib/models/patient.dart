// lib/models/patient.dart

class Patient {
  final int id;
  final String ma;
  final String hovaten;
  final String gioitinh;
  final String sodienthoai;
  final String ngaysinh;
  final String diachi;

  Patient({
    required this.id,
    required this.ma,
    required this.hovaten,
    required this.gioitinh,
    required this.sodienthoai,
    required this.ngaysinh,
    required this.diachi,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      ma: json['ma'] ?? '',
      hovaten: json['hovaten'] ?? '',
      gioitinh: json['gioitinh'] ?? 'Nam',
      sodienthoai: json['sodienthoai'] ?? '',
      ngaysinh: json['ngaysinh'] ?? '',
      diachi: json['diachi'] ?? '',
    );
  }
}