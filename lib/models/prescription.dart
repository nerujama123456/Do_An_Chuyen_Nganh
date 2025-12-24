// lib/models/prescription.dart

class Prescription {
  final String stt;
  final String ma;
  final String tenbenhnhan;
  final String bacsi;
  final int tongtien;
  final String trangthai;

  Prescription({
    required this.stt,
    required this.ma,
    required this.tenbenhnhan,
    required this.bacsi,
    required this.tongtien,
    required this.trangthai,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      stt: json['id'].toString(),
      ma: json['ma'] ?? '',
      tenbenhnhan: json['tenbenhnhan'] ?? 'N/A',
      bacsi: json['bacsi'] ?? 'N/A',
      tongtien: json['tongtien'] is int ? json['tongtien'] : (int.tryParse(json['tongtien'].toString()) ?? 0),
      trangthai: json['trangthai'] ?? '',
    );
  }
}