// lib/screens/cashier/cashier_health_cert_screen.dart

import 'package:flutter/material.dart';
import '../../models/health_certification.dart';
import '../../services/health_cert_service.dart';
import '../../widgets/sidebar.dart';

class CashierHealthCertScreen extends StatefulWidget {
  @override
  _CashierHealthCertScreenState createState() => _CashierHealthCertScreenState();
}

class _CashierHealthCertScreenState extends State<CashierHealthCertScreen> {
  late Future<List<HealthCertification>> _certsFuture;
  final HealthCertService _healthCertService = HealthCertService();

  // Định nghĩa chiều rộng cố định cho các cột (Đồng bộ hóa)
  final Map<String, double> _columnWidths = const {
    'Ma': 200.0,
    'TenBN': 200.0,
    'TieuDe': 150.0,
    'PhongKham': 200.0,
    'TongTien': 150.0,
    'ThanhToan': 150.0,
    'HoatDong': 200.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<HealthCertification> _allCerts = [];
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _certsFuture = Future.value([]); // Khởi tạo mặc định
    _loadData();
  }

  void _loadData() async {
    try {
      final certs = await _healthCertService.fetchHealthCertifications();

      if (mounted) {
        setState(() {
          _allCerts = certs;
          // Lọc chỉ những hồ sơ CHƯA THANH TOÁN
          _certsFuture = Future.value(_filterCerts(_allCerts, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _certsFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC CHỈ CÁC HỒ SƠ CHỜ THANH TOÁN
  List<HealthCertification> _filterCerts(List<HealthCertification> certs, String query) {
    // 1. Lọc theo trạng thái CHƯA THANH TOÁN
    final unpaidCerts = certs.where((cert) => cert.thanhtoan == 'Chưa thanh toán').toList();

    // 2. Lọc theo query (Tên, Mã, v.v.)
    if (query.isEmpty) {
      return unpaidCerts;
    }
    final lowerCaseQuery = query.toLowerCase();

    return unpaidCerts.where((cert) {
      return cert.ma.toLowerCase().contains(lowerCaseQuery) ||
          cert.tenbenhnhan.toLowerCase().contains(lowerCaseQuery) ||
          cert.title.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _certsFuture = Future.value(_filterCerts(_allCerts, _searchQuery));
    });
  }

  // HÀM XỬ LÝ XÁC NHẬN THANH TOÁN
  void _markAsPaid(String certId) async {
    final success = await _healthCertService.markCertAsPaid(certId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác nhận thanh toán thành công!'), backgroundColor: Colors.green),
        );
        _loadData(); // Tải lại danh sách (để hồ sơ đã thanh toán biến mất)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác nhận thanh toán thất bại.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }


  Widget _buildStatusButton(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color, width: 1.5)
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildSearchAndActionButton(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 300, child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Nhập mã, tên hoặc tiêu đề', border: OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)))),
        const SizedBox(width: 10),
        ElevatedButton.icon(onPressed: _performSearch, icon: const Icon(Icons.search), label: const Text('Tìm kiếm'), style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white)),
        const Spacer(),
        // Không có nút Thêm mới ở đây vì Thu ngân không tạo hồ sơ
      ],
    );
  }

  // --- WIDGET CỐ ĐỊNH: HEADER BẢNG ---
  Widget _buildFixedTableHeader() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border(bottom: BorderSide(color: Colors.grey.shade400))),

      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['Ma'], child: const Text('Mã', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TenBN'], child: const Text('Tên bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TieuDe'], child: const Text('Tiêu đề', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['PhongKham'], child: const Text('Phòng khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TongTien'], child: const Text('Tổng tiền (VND)', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['ThanhToan'], child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(HealthCertification cert) {
    final String certIdString = cert.id.toString();
    final Color paymentColor = Colors.red; // Luôn màu đỏ vì đang chờ thanh toán

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['Ma'], child: Text(cert.ma)),
            SizedBox(width: _columnWidths['TenBN'], child: Text(cert.tenbenhnhan)),
            SizedBox(width: _columnWidths['TieuDe'], child: Text(cert.title)),
            SizedBox(width: _columnWidths['PhongKham'], child: Text(cert.phongkham)),
            SizedBox(width: _columnWidths['TongTien'], child: Text(cert.gia.toString())),
            SizedBox(width: _columnWidths['ThanhToan'], child: _buildStatusButton(cert.thanhtoan, paymentColor)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(
              children: [
                // NÚT XÁC NHẬN THANH TOÁN (✓)
                IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.green, size: 20),
                  tooltip: 'Xác nhận thanh toán',
                  onPressed: () => _markAsPaid(certIdString),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/cashier/health_certs';

    return Scaffold(
      body: Row(
        children: <Widget>[
          Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('DANH SÁCH THU NGÂN GIẤY KHÁM BỆNH', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  // Thanh tìm kiếm và nút Thêm
                  _buildSearchAndActionButton(context),
                  const SizedBox(height: 15),

                  // HEADER BẢNG CỐ ĐỊNH
                  _buildFixedTableHeader(),

                  // Bảng dữ liệu CUỘN DỌC
                  Expanded(
                    child: FutureBuilder<List<HealthCertification>>(
                      future: _certsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                        if (snapshot.hasData) {
                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return _buildDataRow(snapshot.data![index]);
                            },
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                          );
                        }
                        return const Center(child: Text('Không có hồ sơ chờ thanh toán.'));
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}