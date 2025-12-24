// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    // Bổ sung locale cho DateFormat nếu chưa có (cần gói intl)
    Intl.defaultLocale = 'vi_VN';
    _statsFuture = _dataService.fetchDashboardStats();
  }

  // Hàm xây dựng biểu đồ Doughnut Chart (Giữ nguyên)
  Widget _buildPieChart(Map<String, dynamic> data) {
    // ... (Logic giữ nguyên) ...
    return const SizedBox();
  }

  // Widget phụ trợ cho legend
  Widget _buildLegendItem(String label, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // Widget phụ trợ cho tổng tiền
  Widget _buildRevenueCard(String title, int amount, {Color color = Colors.green}) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi', symbol: 'VND');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text(currencyFormatter.format(amount), style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // !!! WIDGET HIỂN THỊ TỔNG SỐ LƯỢNG HỒ SƠ DANH MỤC
  Widget _buildCountCard(String title, int count, IconData icon) {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Colors.blue.shade600),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(count.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/home';

    return Scaffold(
      body: Row(
        children: <Widget>[
          Sidebar(currentRoute: currentRoute),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải dữ liệu tổng quan: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                // LẤY DỮ LIỆU TỪ SNAPSHOT
                final tongDoanhThu = snapshot.data!['tong_doanhthu'] as int;
                final certRevenue = snapshot.data!['doanhthu_giaykham'] as int;
                final voucherRevenue = snapshot.data!['doanhthu_phieudv'] as int;
                final prescriptionRevenue = snapshot.data!['doanhthu_donthuoc'] as int;
                final counts = snapshot.data!['counts'] as Map<String, dynamic>; // Danh sách số lượng hồ sơ

                final currencyFormatter = NumberFormat.currency(locale: 'vi', symbol: 'VND');


                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Tiêu đề trang
                      const Text('TỔNG QUAN HỆ THỐNG', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Divider(),

                      // HÀNG 1: TỔNG DOANH THU
                      _buildRevenueCard('TỔNG DOANH THU THỰC TẾ', tongDoanhThu, color: Colors.blue.shade600),
                      const SizedBox(height: 20),

                      // HÀNG 2: PHÂN CHIA DOANH THU (3 CỘT)
                      const Text('PHÂN CHIA DOANH THU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildRevenueCard('GIẤY KHÁM BỆNH', certRevenue, color: Colors.teal)),
                          const SizedBox(width: 15),
                          Expanded(flex: 1, child: _buildRevenueCard('PHIẾU DỊCH VỤ', voucherRevenue, color: Colors.orange)),
                          const SizedBox(width: 15),
                          Expanded(flex: 1, child: _buildRevenueCard('ĐƠN THUỐC', prescriptionRevenue, color: Colors.purple)),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // !!! HÀNG 3: TỔNG SỐ LƯỢNG HỒ SƠ DANH MỤC
                      const Text('TỔNG SỐ LƯỢNG HỒ SƠ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                      const SizedBox(height: 10),

                      GridView.count(
                        crossAxisCount: 5, // 5 cột cho màn hình desktop
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 2.0, // Chiều rộng gấp đôi chiều cao
                        children: [
                          _buildCountCard('Giấy Khám Bệnh hôm nay', counts['health_cert'] as int, Icons.assignment),
                          _buildCountCard('Lượt khám chờ xác nhận', counts['unconfirmed_apps'] as int, Icons.calendar_today),
                          _buildCountCard('Lượt khám đã xác nhận', counts['confirmed_apps'] as int, Icons.calendar_today),
                          _buildCountCard('Đơn Thuốc', counts['prescriptions'] as int, Icons.receipt),
                          _buildCountCard('Phiếu Dịch Vụ', counts['service_vouchers'] as int, Icons.note_add),
                          _buildCountCard('Phòng Khám', counts['consulting_rooms'] as int, Icons.local_hospital),
                          _buildCountCard('Dịch Vụ Khám', counts['medical_services'] as int, Icons.medical_services),
                          _buildCountCard('Loại Thuốc', counts['medicine_types'] as int, Icons.category),
                          _buildCountCard('Thuốc', counts['medicines'] as int, Icons.healing),
                          _buildCountCard('Bệnh Nhân', counts['patients'] as int, Icons.person),
                        ],
                      ),

                      const SizedBox(height: 40),



                      const SizedBox(height: 30),

                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}