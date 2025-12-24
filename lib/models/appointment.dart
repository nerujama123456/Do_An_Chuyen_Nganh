// lib/models/appointment.dart (Đã bổ sung trường thiếu)

class Appointment {
  final String id;
  final String ma;
  final String hovaten;
  final String sodienthoai;
  final String gioitinh;
  final String ngaysinh;
  final String ngaydathen;
  final String giodathen;
  final String trangthai;

  // Thông tin thêm (CẦN THIẾT CHO EDIT SCREEN)
  final int? patient_id;
  final String diachi;   // <-- ĐÃ BỔ SUNG
  final String lydokham; // <-- ĐÃ BỔ SUNG
  final String bacsi; // Tên bác sĩ từ JOIN

  Appointment({
    required this.id,
    required this.ma,
    required this.hovaten,
    required this.sodienthoai,
    required this.gioitinh,
    required this.ngaysinh,
    required this.ngaydathen,
    required this.giodathen,
    required this.trangthai,
    required this.diachi, // <-- BỔ SUNG
    required this.lydokham, // <-- BỔ SUNG
    required this.bacsi,
    this.patient_id,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'].toString(),
      ma: json['ma'] ?? '',
      hovaten: json['hovaten'] ?? '',
      sodienthoai: json['sodienthoai'] ?? '',
      gioitinh: json['gioitinh'] ?? 'N/A',
      ngaysinh: json['ngaysinh'] ?? '',
      ngaydathen: json['ngaydathen'] ?? '',
      giodathen: json['giodathen'] ?? '',
      trangthai: json['trangthai'] ?? 'Chờ xác nhận',

      diachi: json['diachi'] ?? '',     // <-- ÁNH XẠ
      lydokham: json['lydokham'] ?? '', // <-- ÁNH XẠ
      bacsi: json['bacsi'] ?? 'N/A',

      patient_id: json['patient_id'],
    );
  }
}