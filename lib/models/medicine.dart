// lib/models/medicine.dart

class Medicine {
  final int id;
  final String ma;
  final String tenthuoc;
  final String mota;
  final int giavnd;
  final String donvitinh;
  final int loaithuoc_id;
  final String tenloaithuoc; // Từ JOIN

  Medicine({
    required this.id,
    required this.ma,
    required this.tenthuoc,
    required this.mota,
    required this.giavnd,
    required this.donvitinh,
    required this.loaithuoc_id,
    required this.tenloaithuoc,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as int,
      ma: json['ma'] ?? '',
      tenthuoc: json['tenthuoc'] ?? '',
      mota: json['mota'] ?? '',
      donvitinh: json['donvitinh'] ?? '',
      tenloaithuoc: json['tenloaithuoc'] ?? 'N/A', // Từ JOIN
      giavnd: json['giavnd'] is int ? json['giavnd'] : (int.tryParse(json['giavnd'].toString()) ?? 0),
      loaithuoc_id: json['loaithuoc_id'] as int? ?? 0,
    );
  }
}