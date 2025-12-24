// lib/widgets/sidebar.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// --- ĐỊNH NGHĨA DANH SÁCH MENU PHẲNG VÀ HOÀN CHỈNH ---
final List<Map<String, dynamic>> allMenuItems = [
  // 1. NHÓM QUẢN LÝ (Gốc)
  {'title': 'Trang chủ', 'icon': Icons.home, 'route': '/home'},
  {'title': 'Lịch hẹn hôm nay', 'icon': Icons.calendar_today, 'route': '/today_appointments'},
  {'title': 'Lịch hẹn', 'icon': Icons.calendar_today, 'route': '/all_appointments'},
  {'title': 'Giấy khám bệnh', 'icon': Icons.assignment, 'route': '/health_certs'},
  {'title': 'Đơn thuốc', 'icon': Icons.receipt, 'route': '/prescriptions'},
  {'title': 'Phiếu dịch vụ', 'icon': Icons.note_add, 'route': '/service_vouchers'},
  {'title': 'Phòng khám', 'icon': Icons.local_hospital, 'route': '/consulting_rooms'},
  {'title': 'Dịch vụ khám', 'icon': Icons.medical_services, 'route': '/medical_services'},
  {'title': 'Loại thuốc', 'icon': Icons.category, 'route': '/medicine_types'},
  {'title': 'Thuốc', 'icon': Icons.healing, 'route': '/medicines'},
  {'title': 'Bệnh nhân', 'icon': Icons.person, 'route': '/patients'},
  {'title': 'Bác sĩ', 'icon': Icons.person_search, 'route': '/doctors'},

  {'title': 'Giấy khám bệnh (Thu)', 'icon': Icons.assignment, 'route': '/cashier/health_certs'},
  {'title': 'Phiếu dịch vụ (Thu)', 'icon': Icons.note_add, 'route': '/cashier/service_vouchers'},

  // --- CÀI ĐẶT ĐÃ GỘP VÀO ---
  {'title': 'Tài khoản', 'icon': Icons.people, 'route': '/settings/accounts'},

  {'title': 'Đăng xuất', 'icon': Icons.logout, 'route': '/logout'},
];


class Sidebar extends StatelessWidget {
  final String currentRoute;
  final AuthService _authService = AuthService();

  Sidebar({Key? key, this.currentRoute = '/prescriptions'}) : super(key: key);

  void _handleNavigation(BuildContext context, String route) async {
    if (route == '/logout') {
      await _authService.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      if (route != currentRoute) {
        Navigator.pushNamed(context, route);
      }
    }
  }

  // Widget cho mục menu cơ bản (Sử dụng chung)
  Widget _buildSidebarItem(BuildContext context, Map<String, dynamic> item, String roleName) {

    // !!! BỎ QUA NẾU NGƯỜI DÙNG KHÔNG CÓ QUYỀN TRUY CẬP (Logic phân quyền)
    if (!_canViewRoute(item['route'].toString(), roleName)) {
      return const SizedBox.shrink();
    }

    final title = item['title'] as String;
    final route = item['route'] as String;
    final isSelected = currentRoute == route;
    final badge = item['badge'] as int? ?? 0;
    final icon = item['icon'] as IconData;

    final iconSize = 20.0;
    final selectedColor = Theme.of(context).primaryColor;
    final iconColor = isSelected ? selectedColor : Colors.grey[700];
    final textColor = isSelected ? selectedColor : Colors.grey[800];

    const padding = EdgeInsets.only(left: 15, right: 15, top: 12, bottom: 12);


    return InkWell(
      onTap: () => _handleNavigation(context, route),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // LOGIC PHÂN QUYỀN TRÊN FRONTEND
  bool _canViewRoute(String route, String roleName) {
    if (roleName == 'Admin') return true;
    if (route == '/home' || route == '/logout') {
      return roleName != 'Khách'; // Cho phép tất cả vai trò đã đăng nhập
    }
    switch (roleName) {
      case 'Bác sĩ':
        return route.contains('/home') ||route.contains('/today_appointments')||route.contains('/lib/health_certs') || route.contains('/prescriptions') || route.contains('/lib/service_vouchers') || route.contains('/patients')|| route.contains('/logout');

      case 'Nhân viên':
        return route.contains('/home') ||route.contains('/consulting_rooms') || route.contains('/medical_services') || route.contains('/medicine_types') || route.contains('/medicines') || route.contains('/patients') || route.contains('/logout');

      case 'Thu ngân':
        return route.contains('/home') ||route.contains('/cashier') || route.contains('/prescriptions') || route.contains('/patients')|| route.contains('/logout');

      case 'Tiếp tân':
        return route.contains('/home') ||route.contains('/today_appointments')||route.contains('/all_appointments') || route.contains('/patients') || route.contains('/logout');

      default:
        return false;
    }
  }


  @override
  Widget build(BuildContext context) {

    // SỬ DỤNG FUTUREBUILDER ĐỂ TẢI VAI TRÒ
    return FutureBuilder<String>(
      future: _authService.getUserRoleName(),
      builder: (context, snapshot) {
        final roleName = snapshot.data ?? 'Khách';

        return Container(
          width: 200,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Logo/Tên phòng khám
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medical_services, color: Theme.of(context).primaryColor, size: 30),
                    const SizedBox(width: 8),
                    Text('Phòng khám', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tiêu đề QUẢN LÝ
              const Padding(
                padding: EdgeInsets.only(left: 15, top: 15, bottom: 5),
                child: Text('QUẢN LÝ', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ),

              // Danh sách menu phẳng (FLAT LIST)
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Hiển thị tất cả các mục trong danh sách phẳng
                    ...allMenuItems.map((item) => _buildSidebarItem(context, item, roleName)).toList(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // HIỂN THỊ VAI TRÒ HIỆN TẠI
              Container(
                padding: const EdgeInsets.all(10),
                child: Text('Vai trò: ${snapshot.hasData ? roleName : "Đang tải..."}', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ),
              const Divider(height: 1),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}