// lib/screens/medicine_types/medicine_types_screen.dart

import 'package:flutter/material.dart';
import '../../models/medicine_type.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'medicine_type_form_screen.dart';
import 'medicine_type_edit_screen.dart';

class MedicineTypesScreen extends StatefulWidget {
  @override
  _MedicineTypesScreenState createState() => _MedicineTypesScreenState();
}

class _MedicineTypesScreenState extends State<MedicineTypesScreen> {
  late Future<List<MedicineType>> _typesFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'STT': 100.0,
    'Ma': 350.0,
    'TenLoai': 450.0,
    'HoatDong': 350.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<MedicineType> _allTypes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _typesFuture = Future.value([]);
    _loadData();
  }

  void _loadData() async {
    try {
      final maps = await _dataService.fetchMedicineTypes();
      final types = maps.map((map) => MedicineType.fromJson(map)).toList();

      if (mounted) {
        setState(() {
          _allTypes = types;
          _typesFuture = Future.value(_filterTypes(_allTypes, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _typesFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ
  List<MedicineType> _filterTypes(List<MedicineType> types, String query) {
    if (query.isEmpty) {
      return types;
    }
    final lowerCaseQuery = query.toLowerCase();

    return types.where((type) {
      final indexString = (types.indexOf(type) + 1).toString();

      return indexString.contains(lowerCaseQuery) ||
          type.ma.toLowerCase().contains(lowerCaseQuery) ||
          type.tenloaithuoc.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _typesFuture = Future.value(_filterTypes(_allTypes, _searchQuery));
    });
  }


  void _deleteType(int typeId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa loại thuốc này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _dataService.deleteCatalogItem('medicine_types', typeId);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa loại thuốc thành công!'), backgroundColor: Colors.green));
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại. Loại thuốc đang được sử dụng.'), backgroundColor: Colors.red));
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
            SizedBox(width: _columnWidths['TenLoai'], child: const Text('Tên loại thuốc', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(MedicineType type, int index) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(type.ma)),
            SizedBox(width: _columnWidths['TenLoai'], child: Text(type.tenloaithuoc)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(children: [
              // Nút Chỉnh sửa
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => MedicineTypeEditScreen(typeId: type.id, onSave: _loadData),
                    ));
                    _loadData();
                  },
                  tooltip: 'Chỉnh sửa'
              ),
              // Nút Xóa
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteType(type.id), tooltip: 'Xóa'),
            ])),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/medicine_types';

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
                  const Text('DANH SÁCH LOẠI THUỐC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  // THANH TÌM KIẾM
                  Row(
                    children: [
                      SizedBox(
                          width: 300,
                          child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Nhập tên loại thuốc',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              )
                          )
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _performSearch, // Gọi hàm tìm kiếm
                        icon: const Icon(Icons.search),
                        label: const Text('Tìm kiếm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),
                      ),
                      const Spacer(),

                      // Nút Thêm loại thuốc
                      ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => MedicineTypeFormScreen(onSave: _loadData),
                            ));
                            _loadData();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm loại thuốc'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // HEADER BẢNG CỐ ĐỊNH
                  _buildFixedTableHeader(),

                  // Bảng dữ liệu CUỘN DỌC
                  Expanded(
                    child: FutureBuilder<List<MedicineType>>(
                      future: _typesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                        if (snapshot.hasData) {
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
                        return const Center(child: Text('Không có loại thuốc nào.'));
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