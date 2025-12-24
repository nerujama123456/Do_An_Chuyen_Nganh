// lib/screens/cashier/cashier_service_voucher_screen.dart

import 'package:flutter/material.dart';
import '../../models/service_voucher.dart';
import '../../services/service_voucher_service.dart';
import '../../widgets/sidebar.dart';

class CashierServiceVoucherScreen extends StatefulWidget {
  @override
  _CashierServiceVoucherScreenState createState() => _CashierServiceVoucherScreenState();
}

class _CashierServiceVoucherScreenState extends State<CashierServiceVoucherScreen> {
  late Future<List<ServiceVoucher>> _vouchersFuture;
  final ServiceVoucherService _voucherService = ServiceVoucherService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'Ma': 200.0,
    'TenBN': 250.0,
    'DichVu': 270.0,
    'TongTien': 170.0,
    'ThanhToan': 130.0,
    'HoatDong': 200.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<ServiceVoucher> _allVouchers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _vouchersFuture = Future.value([]); // Khởi tạo mặc định
    _loadData();
  }

  void _loadData() async {
    try {
      final vouchers = await _voucherService.fetchServiceVouchers();

      if (mounted) {
        setState(() {
          _allVouchers = vouchers;
          // Lọc chỉ những hồ sơ CHƯA THANH TOÁN
          _vouchersFuture = Future.value(_filterVouchers(_allVouchers, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _vouchersFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  List<ServiceVoucher> _filterVouchers(List<ServiceVoucher> vouchers, String query) {
    // 1. Lọc theo trạng thái CHƯA THANH TOÁN
    final unpaidVouchers = vouchers.where((v) => v.thanhtoan == 'Chưa thanh toán').toList();

    // 2. Lọc theo query (Tên, Mã, v.v.)
    if (query.isEmpty) {
      return unpaidVouchers;
    }
    final lowerCaseQuery = query.toLowerCase();

    return unpaidVouchers.where((v) {
      return v.ma.toLowerCase().contains(lowerCaseQuery) ||
          v.tenbenhnhan.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _vouchersFuture = Future.value(_filterVouchers(_allVouchers, _searchQuery));
    });
  }

  // HÀM XỬ LÝ XÁC NHẬN THANH TOÁN
  void _markAsPaid(String voucherId) async {
    final success = await _voucherService.markVoucherAsPaid(voucherId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán phiếu dịch vụ thành công!'), backgroundColor: Colors.green),
        );
        _loadData();
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
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSearchAndActionButton(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 300, child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Nhập mã hoặc tên bệnh nhân', border: OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)))),
        const SizedBox(width: 10),
        ElevatedButton.icon(onPressed: _performSearch, icon: const Icon(Icons.search), label: const Text('Tìm kiếm'), style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white)),
        const Spacer(),
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
            SizedBox(width: _columnWidths['DichVu'], child: const Text('Dịch vụ khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TongTien'], child: const Text('Tổng tiền (VND)', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['ThanhToan'], child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(ServiceVoucher voucher, int index) {
    final String voucherIdString = voucher.id.toString();
    final Color paymentColor = Colors.red;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['Ma'], child: Text(voucher.ma)),
            SizedBox(width: _columnWidths['TenBN'], child: Text(voucher.tenbenhnhan)),
            SizedBox(width: _columnWidths['DichVu'], child: Text(voucher.dichvukham)),
            SizedBox(width: _columnWidths['TongTien'], child: Text(voucher.tongtien.toString())),
            SizedBox(width: _columnWidths['ThanhToan'], child: _buildStatusButton(voucher.thanhtoan, paymentColor)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(
              children: [
                // NÚT XÁC NHẬN THANH TOÁN (✓)
                IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.green, size: 20),
                  tooltip: 'Xác nhận thanh toán',
                  onPressed: () => _markAsPaid(voucherIdString),
                ),
                // Nút In
              ],
            )),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/cashier/service_vouchers';

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
              const Text('DANH SÁCH THU NGÂN PHIẾU DỊCH VỤ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(),

              _buildSearchAndActionButton(context),
              const SizedBox(height: 15),

              // HEADER BẢNG CỐ ĐỊNH
              _buildFixedTableHeader(),

              // Bảng dữ liệu CUỘN DỌC
              Expanded(
                child: FutureBuilder<List<ServiceVoucher>>(
                  future: _vouchersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return _buildDataRow(snapshot.data![index], index);
                        },
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                      );
                    }
                    return const Center(child: Text('Không có phiếu dịch vụ chờ thanh toán.'));
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