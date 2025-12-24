// lib/models/health_certification.dart

class HealthCertification {
  final String id;
  final String ma;
  final String title;

  final String tenbenhnhan;
  final String phongkham;
  final String bacsi;

  final String ngay;
  final String trangthai;
  final String thanhtoan;
  final int gia;

  final int? patient_id;         // <-- SỬA TẠI ĐÂY
  final int? phongkham_id;       // <-- SỬA TẠI ĐÂY
  final String? user_id;         // <-- SỬA TẠI ĐÂY
  final int? prescription_id;
  final String? ketluan;
  final String? huongdandieutri;
  final String? denghikhamlamsang;

  HealthCertification({
    required this.id,
    required this.ma,
    required this.title,
    required this.tenbenhnhan,
    required this.phongkham,
    required this.bacsi,
    required this.ngay,
    required this.trangthai,
    required this.thanhtoan,
    required this.gia,
    this.patient_id,         // <-- SỬA
    this.phongkham_id,       // <-- SỬA
    this.user_id,            // <-- SỬA
    this.prescription_id,
    this.ketluan,
    this.huongdandieutri,
    this.denghikhamlamsang,
  });

  factory HealthCertification.fromJson(Map<String, dynamic> json) {
    return HealthCertification(
      id: json['id'].toString(),
      ma: json['ma'] ?? '',
      title: json['title'] ?? '',

      tenbenhnhan: json['tenbenhnhan'] ?? 'N/A',
      phongkham: json['phongkham'] ?? 'N/A',
      bacsi: json['bacsi'] ?? 'N/A',

      ngay: json['ngay'] ?? '',
      trangthai: json['trangthai'] ?? 'Chưa khám',
      thanhtoan: json['thanhtoan'] ?? 'Chưa thanh toán',
      gia: json['gia'] is int ? json['gia'] : (int.tryParse(json['gia'].toString()) ?? 0),

      ketluan: json['ketluan'],
      huongdandieutri: json['huongdandieutri'],
      denghikhamlamsang: json['denghikhamlamsang'],
    );
  }
}