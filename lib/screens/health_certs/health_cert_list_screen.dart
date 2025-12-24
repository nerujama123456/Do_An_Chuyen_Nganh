// lib/screens/health_certs/health_cert_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/health_certification.dart';
import '../../services/health_cert_service.dart';
import '../../widgets/sidebar.dart';
import 'health_cert_edit_screen.dart';
import 'health_cert_form_screen.dart';
import 'health_cert_detail_screen.dart';

class HealthCertListScreen extends StatefulWidget {
  @override
  _HealthCertListScreenState createState() => _HealthCertListScreenState();
}

class _HealthCertListScreenState extends State<HealthCertListScreen> {
  late Future<List<HealthCertification>> _healthCertsFuture;
  final HealthCertService _healthCertService = HealthCertService();

  // Định nghĩa chiều rộng cố định cho các cột (Để đồng bộ với TodayAppointment)
  final Map<String, double> _columnWidths = const {
    'STT': 50.0,
    'Ma': 150.0,
    'TenBN': 150.0,
    'TieuDe': 150.0,
    'PhongKham': 150.0,
    'BacSi': 150.0,
    'Ngay': 100.0,
    'TrangThai': 95.0,
    'ThanhToan': 125.0,
    'HoatDong': 130.0,
  };


  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<HealthCertification> _allCerts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _healthCertsFuture = Future.value([]);
    _loadData();
  }

  void _loadData() async {
    try {
      final certs = await _healthCertService.fetchHealthCertifications();

      if (mounted) {
        setState(() {
          _allCerts = certs;
          _healthCertsFuture = Future.value(_filterCerts(_allCerts, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _healthCertsFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  List<HealthCertification> _filterCerts(List<HealthCertification> certs, String query) {
    if (query.isEmpty) {
      return certs;
    }
    final lowerCaseQuery = query.toLowerCase();

    return certs.where((cert) {
      return cert.ma.toLowerCase().contains(lowerCaseQuery) ||
          cert.tenbenhnhan.toLowerCase().contains(lowerCaseQuery) ||
          cert.title.toLowerCase().contains(lowerCaseQuery) ||
          cert.phongkham.toLowerCase().contains(lowerCaseQuery) ||
          cert.bacsi.toLowerCase().contains(lowerCaseQuery) ||
          cert.ngay.contains(lowerCaseQuery);
    }).toList();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _healthCertsFuture = Future.value(_filterCerts(_allCerts, _searchQuery));
    });
  }


  void _markAsExamined(String certId) async {
    final success = await _healthCertService.markHealthCertAsExamined(certId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu giấy khám bệnh là Đã khám!')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật trạng thái.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _deleteCert(String certId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hồ sơ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _healthCertService.deleteHealthCertification(certId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa hồ sơ thành công!'), backgroundColor: Colors.green));
          _loadData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: ${e.toString()}'), backgroundColor: Colors.red));
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
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Nhập tên bệnh nhân',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _performSearch,
          icon: const Icon(Icons.search),
          label: const Text('Tìm kiếm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
        const Spacer(),
        // Nút Thêm Giấy Khám Bệnh
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (context) => HealthCertFormScreen(onSave: _loadData),
            ));
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm Giấy Khám Bệnh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
      ],
    );
  }

  // PHẦN CỐ ĐỊNH: Header Bảng (Tên cột)
  Widget _buildFixedTableHeader() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border(bottom: BorderSide(color: Colors.grey.shade400))),

      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: const Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['Ma'], child: const Text('Mã', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TenBN'], child: const Text('Tên bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TieuDe'], child: const Text('Tiêu đề', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['PhongKham'], child: const Text('Phòng khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['BacSi'], child: const Text('Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['Ngay'], child: const Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TrangThai'], child: const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['ThanhToan'], child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // PHẦN CUỘN: Một hàng dữ liệu
  Widget _buildDataRow(HealthCertification cert, int index) {
    final String certIdString = cert.id.toString();

    final Color statusColor = cert.trangthai == 'Đã khám' ? Colors.green : Colors.red;
    final Color paymentColor = cert.thanhtoan == 'Đã thanh toán' ? Colors.green : Colors.red;

    final bool canEditBasic = cert.trangthai == 'Chưa khám';
    final bool canConclude = cert.trangthai == 'Chưa khám' && cert.thanhtoan == 'Đã thanh toán';
    final bool canDelete = cert.trangthai == 'Chưa khám' && cert.thanhtoan == 'Chưa thanh toán';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(cert.ma)),
            SizedBox(width: _columnWidths['TenBN'], child: Text(cert.tenbenhnhan)),
            SizedBox(width: _columnWidths['TieuDe'], child: Text(cert.title)),
            SizedBox(width: _columnWidths['PhongKham'], child: Text(cert.phongkham)),
            SizedBox(width: _columnWidths['BacSi'], child: Text(cert.bacsi)),
            SizedBox(width: _columnWidths['Ngay'], child: Text(cert.ngay)),
            SizedBox(width: _columnWidths['TrangThai'], child: _buildStatusButton(cert.trangthai, statusColor)),
            SizedBox(width: _columnWidths['ThanhToan'], child: _buildStatusButton(cert.thanhtoan, paymentColor)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(
              children: [
                // Nút Xem thông tin
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  tooltip: 'Xem thông tin',
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => HealthCertDetailScreen(certId: certIdString, isEditing: false),
                    ));
                    if (result == true) {
                      _loadData();
                    }
                  },
                ),

                // NÚT KẾT LUẬN (🖋️)
                if (canConclude)
                  IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                      tooltip: 'Kết luận khám bệnh',
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(
                          builder: (context) => HealthCertDetailScreen(certId: certIdString, isEditing: true),
                        ));
                        if (result == true) {
                          _loadData();
                        }
                      }),

                // NÚT XÓA
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'Xóa hồ sơ',
                    onPressed: () => _deleteCert(certIdString),
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
    const String currentRoute = '/health_certs';

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

                  const Text('DANH SÁCH GIẤY KHÁM BỆNH', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  _buildSearchAndActionButton(context),
                  const SizedBox(height: 15),
                  _buildFixedTableHeader(),
                  // Bảng dữ liệu CUỘN DỌC
                  Expanded(
                    child: FutureBuilder<List<HealthCertification>>(
                      future: _healthCertsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                          );
                        } else if (snapshot.hasData) {
                          // ListView.separated để cuộn dọc và thêm đường kẻ
                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return _buildDataRow(snapshot.data![index], index);
                            },
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                          );
                        } else {
                          return const Center(child: Text('Không có giấy khám bệnh nào.'));
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Thêm khoảng trống dưới cùng
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}