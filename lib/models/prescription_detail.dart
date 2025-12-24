// lib/models/prescription_detail.dart

class PrescriptionDetail {
  final int id;
  // !!! CHUẨN HÓA TÊN BIẾN THÀNH CHỮ THƯỜNG
  final int prescription_id;
  final int medicine_id;
  final String tenthuoc;
  final String donvitinh;
  final int soluong;
  final String cachdung;
  final int giavnd;
  final int tongtien;

  PrescriptionDetail({
    required this.id,
    required this.prescription_id,
    required this.medicine_id,
    required this.tenthuoc,
    required this.donvitinh,
    required this.soluong,
    required this.cachdung,
    required this.giavnd,
    required this.tongtien,
  });

  factory PrescriptionDetail.fromJson(Map<String, dynamic> json) {
    return PrescriptionDetail(
      id: json['id'] as int,
      prescription_id: json['prescription_id'] as int,
      medicine_id: json['medicine_id'] as int, // Khóa ngoại
      tenthuoc: json['tenthuoc'] ?? 'N/A',
      donvitinh: json['donvitinh'] ?? '',
      soluong: json['soluong'] as int,
      cachdung: json['cachdung'] ?? '',
      giavnd: json['giavnd'] is int ? json['giavnd'] : 0,
      tongtien: json['tongtien'] is int ? json['tongtien'] : 0,
    );
  }
}