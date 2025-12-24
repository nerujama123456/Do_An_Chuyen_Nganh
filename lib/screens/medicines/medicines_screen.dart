// lib/screens/medicines/medicines_screen.dart

import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'medicine_form_screen.dart';
import 'medicine_edit_screen.dart';

class MedicinesScreen extends StatefulWidget {
  @override
  _MedicinesScreenState createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  late Future<List<Medicine>> _medicinesFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'STT': 50.0,
    'Ma': 200.0,
    'TenThuoc': 200.0,
    'LoaiThuoc': 200.0,
    'Gia': 150.0,
    'DonViTinh': 150.0,
    'MoTa': 80.0,
    'HoatDong': 200.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _allMedicines = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _medicinesFuture = Future.value([]); // Khởi tạo mặc định
    _loadData();
  }

  void _loadData() async {
    try {
      final medicines = await _dataService.fetchMedicinesList();

      if (mounted) {
        setState(() {
          _allMedicines = medicines;
          _medicinesFuture = Future.value(_filterMedicines(_allMedicines, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _medicinesFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ THUỐC
  List<Medicine> _filterMedicines(List<Medicine> medicines, String query) {
    if (query.isEmpty) {
      return medicines;
    }
    final lowerCaseQuery = query.toLowerCase();

    return medicines.where((medicine) {
      final indexString = (medicines.indexOf(medicine) + 1).toString();
      final giavndString = medicine.giavnd.toString();

      return indexString.contains(lowerCaseQuery) ||
          medicine.ma.toLowerCase().contains(lowerCaseQuery) ||
          medicine.tenthuoc.toLowerCase().contains(lowerCaseQuery) ||
          medicine.tenloaithuoc.toLowerCase().contains(lowerCaseQuery) ||
          giavndString.contains(lowerCaseQuery) ||
          medicine.donvitinh.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _medicinesFuture = Future.value(_filterMedicines(_allMedicines, _searchQuery));
    });
  }


  void _showDescriptionDialog(String ma, String mota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mô tả Thuốc #${ma}'),
        content: Text(mota.isEmpty ? 'Không có mô tả chi tiết.' : mota),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],

      ),


    );
  }

  void _deleteMedicine(int medicineId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa thuốc'),
        content: const Text('Bạn có chắc chắn muốn xóa thuốc này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _dataService.deleteCatalogItem('medicines', medicineId);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thuốc thành công!'), backgroundColor: Colors.green));
          _loadData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
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
            SizedBox(width: _columnWidths['TenThuoc'], child: const Text('Tên thuốc', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['LoaiThuoc'], child: const Text('Loại thuốc', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['Gia'], child: const Text('Giá (VND)', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DonViTinh'], child: const Text('Đơn vị tính', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['MoTa'], child: const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(Medicine medicine, int index) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(medicine.ma)),
            SizedBox(width: _columnWidths['TenThuoc'], child: Text(medicine.tenthuoc)),
            SizedBox(width: _columnWidths['LoaiThuoc'], child: Text(medicine.tenloaithuoc)),
            SizedBox(width: _columnWidths['Gia'], child: Text(medicine.giavnd.toString())),
            SizedBox(width: _columnWidths['DonViTinh'], child: Text(medicine.donvitinh)),
            SizedBox(width: _columnWidths['MoTa'], child: ElevatedButton(
              onPressed: () => _showDescriptionDialog(medicine.ma, medicine.mota),
              child: const Text('Xem'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
            )
            ),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(
              children: [
                // Nút Chỉnh sửa
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => MedicineEditScreen(medicineId: medicine.id, onSave: _loadData),
                      ));
                      _loadData();
                    },
                    tooltip: 'Chỉnh sửa'
                ),
                // Nút Xóa
                IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteMedicine(medicine.id), tooltip: 'Xóa'),
              ],
            )),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/medicines';

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
              const Text('DANH SÁCH THUỐC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(),

              // Thanh tìm kiếm và Thêm mới
              Row(
                children: [
                  SizedBox(
                      width: 300,
                      child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tên thuốc',
                            border: OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          )
                      )
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(onPressed: _performSearch, icon: const Icon(Icons.search), label: const Text('Tìm kiếm'),style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)),
                  const Spacer(),
                  ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (context) => MedicineFormScreen(onSave: _loadData),
                        ));
                        _loadData();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm thuốc'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // HEADER BẢNG CỐ ĐỊNH
              _buildFixedTableHeader(),

              // Bảng dữ liệu CUỘN DỌC
              Expanded(
                child: FutureBuilder<List<Medicine>>(
                  future: _medicinesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      // ListView.separated để cuộn dọc và thêm đường kẻ
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return _buildDataRow(snapshot.data![index], index);
                        },
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                      );
                    }
                    return const Center(child: Text('Không có thuốc nào.'));
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