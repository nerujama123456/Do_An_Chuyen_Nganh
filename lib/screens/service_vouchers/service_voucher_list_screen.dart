// lib/screens/service_vouchers/service_voucher_list_screen.dart

import 'package:flutter/material.dart';
import 'package:my_first_app/screens/service_vouchers/service_voucher_edit_screen.dart';
import '../../models/service_voucher.dart';
import '../../services/service_voucher_service.dart';
import '../../widgets/sidebar.dart';
import 'service_voucher_form_screen.dart';
import 'service_voucher_detail_screen.dart'; // Import màn hình chi tiết

class ServiceVoucherListScreen extends StatefulWidget {
  @override
  _ServiceVoucherListScreenState createState() => _ServiceVoucherListScreenState();
}

class _ServiceVoucherListScreenState extends State<ServiceVoucherListScreen> {
  late Future<List<ServiceVoucher>> _vouchersFuture;
  final ServiceVoucherService _voucherService = ServiceVoucherService();

  // Định nghĩa chiều rộng cố định cho các cột (Đồng bộ hóa)
  final Map<String, double> _columnWidths = const {
    'STT': 30.0,
    'Ma': 150.0,
    'TenBN': 150.0,
    'DichVu': 150.0,
    'BacSi': 120.0,
    'NgayBatDau': 110.0,
    'NgayKetThuc': 110.0,
    'TrangThai': 130.0,
    'ThanhToan': 130.0,
    'HoatDong': 170.0,
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
          _allVouchers = vouchers; // Lưu danh sách gốc
          _vouchersFuture = Future.value(_filterVouchers(_allVouchers, _searchQuery)); // Lọc lần đầu
        });
      }
    } catch (e) {
      if (mounted) {
        _vouchersFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ
  List<ServiceVoucher> _filterVouchers(List<ServiceVoucher> vouchers, String query) {
    if (query.isEmpty) {
      return vouchers;
    }
    final lowerCaseQuery = query.toLowerCase();

    return vouchers.where((voucher) {
      return voucher.ma.toLowerCase().contains(lowerCaseQuery) ||
          voucher.tenbenhnhan.toLowerCase().contains(lowerCaseQuery) ||
          voucher.dichvukham.toLowerCase().contains(lowerCaseQuery) ||
          voucher.bacsi.toLowerCase().contains(lowerCaseQuery) ||
          voucher.ngaybatdau.contains(lowerCaseQuery) ||
          voucher.ngayketthuc.contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _vouchersFuture = Future.value(_filterVouchers(_allVouchers, _searchQuery));
    });
  }
  void _deleteVoucher(String voucherId) async {
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
        await _voucherService.deleteServiceVoucher(voucherId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa hồ sơ thành công!'), backgroundColor: Colors.green));
          _loadData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }
  // HÀM MỚI: Xử lý Hoàn thành Khám (Chuyển trạng thái)
  void _markAsCompleted(String voucherId) async {
    final success = await _voucherService.markVoucherAsCompleted(voucherId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phiếu dịch vụ đã hoàn thành khám!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể hoàn thành phiếu (Chưa thanh toán?).'), backgroundColor: Colors.red));
      }
      _loadData();
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
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController, // Gán Controller
            decoration: InputDecoration(
              hintText: 'Nhập tên bệnh nhân',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _performSearch, // Gọi hàm tìm kiếm
          icon: const Icon(Icons.search),
          label: const Text('Tìm kiếm'),
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
        ),
        const Spacer(),
        // Nút Thêm Phiếu Dịch Vụ
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (context) => ServiceVoucherFormScreen(onSave: _loadData),
            ));
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm phiếu dịch vụ'),
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
        ),

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
            SizedBox(width: _columnWidths['STT'], child: const Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['Ma'], child: const Text('Mã', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TenBN'], child: const Text('Tên bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DichVu'], child: const Text('Dịch vụ khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['BacSi'], child: const Text('Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['NgayBatDau'], child: const Text('Ngày bắt đầu', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['NgayKetThuc'], child: const Text('Ngày kết thúc', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TrangThai'], child: const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['ThanhToan'], child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // PHẦN CUỘN: Một hàng dữ liệu
  Widget _buildDataRow(ServiceVoucher voucher, int index) {
    final Color statusColor = voucher.trangthai == 'Đã khám xong' ? Colors.green : Colors.red;
    final Color paymentColor = voucher.thanhtoan == 'Đã thanh toán' ? Colors.green : Colors.red;
    final bool canComplete = voucher.trangthai == 'Chưa khám xong' && voucher.thanhtoan == 'Đã thanh toán';
    final bool canEdit = voucher.trangthai == 'Chưa khám xong'; // Chỉ chỉnh sửa khi chưa xong

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(voucher.ma)),
            SizedBox(width: _columnWidths['TenBN'], child: Text(voucher.tenbenhnhan)),
            SizedBox(width: _columnWidths['DichVu'], child: Text(voucher.dichvukham)),
            SizedBox(width: _columnWidths['BacSi'], child: Text(voucher.bacsi)),
            SizedBox(width: _columnWidths['NgayBatDau'], child: Text(voucher.ngaybatdau)),
            SizedBox(width: _columnWidths['NgayKetThuc'], child: Text(voucher.ngayketthuc)),
            SizedBox(width: _columnWidths['TrangThai'], child: _buildStatusButton(voucher.trangthai, statusColor)),
            SizedBox(width: _columnWidths['ThanhToan'], child: _buildStatusButton(voucher.thanhtoan, paymentColor)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(children: [
              // Nút Xem chi tiết
              IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ServiceVoucherDetailScreen(voucherId: voucher.id),
                    ));
                  },
                  tooltip: 'Xem chi tiết'
              ),
              // Nút In
              if (canComplete)
                IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.green, size: 20),
                  tooltip: 'Hoàn thành khám',
                  onPressed: () => _markAsCompleted(voucher.id),
                ),

              // Nút Chỉnh sửa (Chỉ khi chưa khám xong)
              if (canEdit)

                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ServiceVoucherEditScreen(voucherId: voucher.id, onSave: _loadData),
                      ));
                      _loadData();
                    },
                    tooltip: 'Chỉnh sửa'
                ),

              if (canEdit)
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => {_deleteVoucher( voucher.id)},
                    tooltip: 'Xóa phiếu dịch vụ',
                    padding: EdgeInsets.zero
                ),

            ])),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/service_vouchers';
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
              const Text('DANH SÁCH PHIẾU DỊCH VỤ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(),

              // Thanh tìm kiếm và nút Thêm
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
                    return const Center(child: Text('Không có phiếu dịch vụ nào.'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ],
    ),
    );
  }
}