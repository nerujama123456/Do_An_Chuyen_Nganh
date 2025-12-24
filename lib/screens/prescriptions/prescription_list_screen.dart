// lib/screens/prescriptions/prescription_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/prescription.dart';
import '../../widgets/sidebar.dart';
import '../../services/prescription_service.dart';
import 'prescription_form_screen.dart';
import 'prescription_detail_screen.dart';
import 'prescription_edit_screen.dart'; // Import màn hình chỉnh sửa

class PrescriptionListScreen extends StatefulWidget {
  @override
  _PrescriptionListScreenState createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  late Future<List<Prescription>> _prescriptionsFuture;
  final PrescriptionService _prescriptionService = PrescriptionService();

  // Định nghĩa chiều rộng cố định cho các cột (Đồng bộ hóa)
  final Map<String, double> _columnWidths = const {
    'STT': 70.0,
    'Ma': 220.0,
    'TenBN': 220.0,
    'BacSi': 220.0,
    'TongTien': 170.0,
    'TrangThai': 150.0,
    'HoatDong': 220.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<Prescription> _allPrescriptions = [];
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _prescriptionsFuture = Future.value([]); // Khởi tạo mặc định
    _loadData();
  }

  void _loadData() async {
    try {
      final prescriptions = await _prescriptionService.fetchPrescriptions();

      if (mounted) {
        setState(() {
          _allPrescriptions = prescriptions;
          _prescriptionsFuture = Future.value(_filterPrescriptions(_allPrescriptions, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _prescriptionsFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ ĐƠN THUỐC
  List<Prescription> _filterPrescriptions(List<Prescription> prescriptions, String query) {
    if (query.isEmpty) {
      return prescriptions;
    }
    final lowerCaseQuery = query.toLowerCase();

    return prescriptions.where((prescription) {
      final tongtienString = prescription.tongtien.toString();

      return prescription.ma.toLowerCase().contains(lowerCaseQuery) ||
          prescription.tenbenhnhan.toLowerCase().contains(lowerCaseQuery) ||
          prescription.bacsi.toLowerCase().contains(lowerCaseQuery) ||
          tongtienString.contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _prescriptionsFuture = Future.value(_filterPrescriptions(_allPrescriptions, _searchQuery));
    });
  }


  // HÀM XỬ LÝ XÁC NHẬN THANH TOÁN
  void _completePayment(String prescriptionId) async {
    final success = await _prescriptionService.completePrescriptionPayment(prescriptionId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán và hoàn thành đơn thuốc thành công!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác nhận thanh toán thất bại.'), backgroundColor: Colors.red),
        );
      }
      _loadData();
    }
  }

  // HÀM XỬ LÝ XÓA ĐƠN THUỐC
  void _deletePrescription(String prescriptionId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa đơn thuốc'),
        content: const Text('Bạn có chắc chắn muốn xóa đơn thuốc này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _prescriptionService.deletePrescription(prescriptionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa đơn thuốc thành công!'), backgroundColor: Colors.green));
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: ${e.toString()}'), backgroundColor: Colors.red));
        }
      }
    }
  }


  // Widget tạo nút trạng thái
  Widget _buildStatusButton(String status) {
    Color color;
    if (status == 'Hoàn thành') {
      color = Colors.green;
    } else if (status == 'Chưa mua') {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

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
  Widget _buildSearchAndActionButton() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController, // Gán controller
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[500],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
        const Spacer(),
        // Nút Thêm Đơn thuốc
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (context) => PrescriptionFormScreen(onSave: _loadData),
            ));
            _loadData();
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm đơn thuốc'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[500],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
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
            SizedBox(width: _columnWidths['BacSi'], child: const Text('Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TongTien'], child: const Text('Tổng tiền (VND)', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TrangThai'], child: const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(Prescription prescription, int index) {
    final String prescriptionIdString = prescription.stt;
    final bool canPay = prescription.trangthai == 'Chưa mua';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(prescription.ma)),
            SizedBox(width: _columnWidths['TenBN'], child: Text(prescription.tenbenhnhan)),
            SizedBox(width: _columnWidths['BacSi'], child: Text(prescription.bacsi)),
            SizedBox(width: _columnWidths['TongTien'], child: Text(prescription.tongtien.toString())),
            SizedBox(width: _columnWidths['TrangThai'], child: _buildStatusButton(prescription.trangthai)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(
              children: [
                // Nút Xem chi tiết
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  tooltip: 'Xem chi tiết đơn thuốc',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PrescriptionDetailScreen(prescriptionId: prescriptionIdString),
                    ));
                  },
                ),

                // NÚT XÁC NHẬN THANH TOÁN
                if (canPay)
                  IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.green, size: 20),
                    tooltip: 'Xác nhận thanh toán / Hoàn thành',
                    onPressed: () => _completePayment(prescriptionIdString),
                  ),


                // Chỉ hiển thị Sửa/Xóa nếu trạng thái là 'Chưa mua'
                if (canPay) ...[
                  IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                      tooltip: 'Chỉnh sửa',
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PrescriptionEditScreen(prescriptionId: prescriptionIdString, onSave: _loadData),
                        ));
                        _loadData();
                      }
                  ),
                  // NÚT XÓA
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'Xóa',
                    onPressed: () => _deletePrescription(prescriptionIdString),
                  ),
                ],
              ],
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/prescriptions';

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
                  const Text('DANH SÁCH ĐƠN THUỐC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  _buildSearchAndActionButton(),
                  const SizedBox(height: 15),

                  // HEADER BẢNG CỐ ĐỊNH
                  _buildFixedTableHeader(),

                  // PHẦN CUỘN: LIST DỮ LIỆU
                  Expanded(
                    child: FutureBuilder<List<Prescription>>(
                      future: _prescriptionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'Lỗi tải dữ liệu: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        } else if (snapshot.hasData) {
                          // ListView.separated để cuộn dọc và thêm đường kẻ
                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return _buildDataRow(snapshot.data![index], index); // Truyền index
                            },
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                          );
                        } else {
                          return const Center(child: Text('Không có đơn thuốc nào.'));
                        }
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