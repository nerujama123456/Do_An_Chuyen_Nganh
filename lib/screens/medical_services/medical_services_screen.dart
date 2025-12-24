// lib/screens/medical_services/medical_services_screen.dart

import 'package:flutter/material.dart';
import '../../models/medical_service.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'medical_service_form_screen.dart';
import 'medical_service_edit_screen.dart';

class MedicalServicesScreen extends StatefulWidget {
  @override
  _MedicalServicesScreenState createState() => _MedicalServicesScreenState();
}

class _MedicalServicesScreenState extends State<MedicalServicesScreen> {
  late Future<List<MedicalService>> _servicesFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'STT': 100.0,
    'Ma': 250.0,
    'TenDichVu': 400.0,
    'Gia': 300.0,
    'HoatDong': 200.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<MedicalService> _allServices = [];
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _servicesFuture = Future.value([]); // Khởi tạo mặc định
    _loadData();
  }

  void _loadData() async {
    try {
      final maps = await _dataService.fetchMedicalServices();
      final services = maps.map((map) => MedicalService.fromJson(map)).toList();

      if (mounted) {
        setState(() {
          _allServices = services;
          _servicesFuture = Future.value(_filterServices(_allServices, _searchQuery)); // Lọc lần đầu
        });
      }
    } catch (e) {
      if (mounted) {
        _servicesFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ
  List<MedicalService> _filterServices(List<MedicalService> services, String query) {
    if (query.isEmpty) {
      return services;
    }
    final lowerCaseQuery = query.toLowerCase();

    return services.where((service) {
      final priceString = service.giavnd.toString();

      return service.ma.toLowerCase().contains(lowerCaseQuery) ||
          service.tendichvu.toLowerCase().contains(lowerCaseQuery) ||
          priceString.contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _servicesFuture = Future.value(_filterServices(_allServices, _searchQuery));
    });
  }


  void _deleteService(int serviceId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa dịch vụ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _dataService.deleteCatalogItem('medical_services', serviceId);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa dịch vụ thành công!'), backgroundColor: Colors.green));
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại. Dịch vụ đang được sử dụng.'), backgroundColor: Colors.red));
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
            SizedBox(width: _columnWidths['TenDichVu'], child: const Text('Tên dịch vụ khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['Gia'], child: const Text('Giá (VND)', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(MedicalService service, int index) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(service.ma)),
            SizedBox(width: _columnWidths['TenDichVu'], child: Text(service.tendichvu)),
            SizedBox(width: _columnWidths['Gia'], child: Text('${service.giavnd} VND')),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(children: [
              // Nút Chỉnh sửa
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => MedicalServiceEditScreen(serviceId: service.id, onSave: _loadData),
                    ));
                    _loadData();
                  },
                  tooltip: 'Chỉnh sửa'
              ),
              // Nút Xóa
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteService(service.id), tooltip: 'Xóa'),
            ])),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/medical_services';

    return Scaffold(
      body: Row(
          children: <Widget>[
          Sidebar(currentRoute: currentRoute),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column( // Column chứa Fixed Header
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('DANH SÁCH DỊCH VỤ KHÁM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(),

              // Thanh tìm kiếm và Thêm mới
              Row(
                children: [
                  SizedBox(
                      width: 300,
                      child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tên dịch vụ khám',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          )
                      )
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
                  // Nút Thêm dịch vụ
                  ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (context) => MedicalServiceFormScreen(onSave: _loadData),
                        ));
                        _loadData();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm dịch vụ khám'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // HEADER BẢNG CỐ ĐỊNH
              _buildFixedTableHeader(),

              // Bảng dữ liệu CUỘN DỌC
              Expanded(
                child: FutureBuilder<List<MedicalService>>(
                  future: _servicesFuture,
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
                    return const Center(child: Text('Không có dịch vụ nào.'));
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