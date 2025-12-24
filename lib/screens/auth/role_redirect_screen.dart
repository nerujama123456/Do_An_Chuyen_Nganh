// lib/screens/auth/role_redirect_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RoleRedirectScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  RoleRedirectScreen({super.key});

  // Hàm kiểm tra vai trò và điều hướng
  Future<void> _checkAndRedirect(BuildContext context) async {
    final roleName = await _authService.getUserRoleName();

    if (roleName == 'Admin') {
      // Admin thấy tất cả, chuyển đến trang danh sách chính
      Navigator.pushReplacementNamed(context, '/home');
    } else if (roleName == 'Bác sĩ' || roleName == 'Thu ngân'|| roleName == 'Nhân viên') {
      // Bác sĩ/Thu ngân thấy các chức năng nghiệp vụ, chuyển đến Giấy Khám Bệnh
      Navigator.pushReplacementNamed(context, '/home');
    } else if (roleName == 'Khách') {
      // Nếu chưa đăng nhập hoặc lỗi, đưa về màn hình login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Các vai trò người dùng khác có thể được điều hướng đến trang riêng
      Navigator.pushReplacementNamed(context, '/patients'); // Giả định người dùng thường chỉ thấy hồ sơ của mình
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kích hoạt kiểm tra ngay khi widget được render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRedirect(context);
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}