// lib/models/service_voucher.dart

class ServiceVoucher {
  final String id;
  final String ma;
  final String tenbenhnhan;
  final String dichvukham;
  // !!! ĐÃ BỎ: final String phongkham;
  final String bacsi;
  final String ngaybatdau;
  final String ngayketthuc;
  final int tongtien;
  final String trangthai;
  final String thanhtoan;

  // Khóa ngoại
  final int? patient_id;
  final int? dichvukham_id;
  // !!! ĐÃ BỎ: final int? phongkham_id;
  final String? user_id;

  ServiceVoucher({
    required this.id,
    required this.ma,
    required this.tenbenhnhan,
    required this.dichvukham,
    // required this.phongkham, // ĐÃ BỎ
    required this.bacsi,
    required this.ngaybatdau,
    required this.ngayketthuc,
    required this.tongtien,
    required this.trangthai,
    required this.thanhtoan,
    this.patient_id,
    this.dichvukham_id,
    // this.phongkham_id, // ĐÃ BỎ
    this.user_id,
  });

  factory ServiceVoucher.fromJson(Map<String, dynamic> json) {
    return ServiceVoucher(
      id: json['id'].toString(),
      ma: json['ma'] ?? '',
      // Lấy từ JOIN
      tenbenhnhan: json['tenbenhnhan'] ?? 'N/A',
      dichvukham: json['dichvukham'] ?? 'N/A',
      bacsi: json['bacsi'] ?? 'N/A',

      ngaybatdau: json['ngaybatdau'] ?? '',
      ngayketthuc: json['ngayketthuc'] ?? '',
      tongtien: json['tongtien'] is int ? json['tongtien'] : (int.tryParse(json['tongtien'].toString()) ?? 0),
      trangthai: json['trangthai'] ?? 'Chưa khám xong',
      thanhtoan: json['thanhtoan'] ?? 'Chưa thanh toán',

      patient_id: json['patient_id'],
      dichvukham_id: json['dichvukham_id'],
      user_id: json['user_id'],
    );
  }
}