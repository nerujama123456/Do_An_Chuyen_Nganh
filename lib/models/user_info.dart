// lib/models/user_info.dart

class UserInfo {
  final String auth_id;
  final String hovaten;
  final String gioitinh;
  final String sodienthoai;
  final String ngaysinh;
  final String diachi;
  final int role_id;
  final String role_name; // Từ JOIN

  UserInfo({
    required this.auth_id,
    required this.hovaten,
    required this.gioitinh,
    required this.sodienthoai,
    required this.ngaysinh,

    required this.diachi,
    required this.role_id,
    required this.role_name,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      auth_id: json['auth_id'] ?? '',
      hovaten: json['hovaten'] ?? '',
      gioitinh: json['gioitinh'] ?? 'N/A',
      sodienthoai: json['sodienthoai'] ?? '',
      ngaysinh: json['ngaysinh'] ?? '',

      diachi: json['diachi'] ?? '',
      role_id: json['role_id'] as int? ?? 0,
      role_name: json['role_name'] ?? json['tenvaitro'] ?? 'Khách',
    );
  }
}