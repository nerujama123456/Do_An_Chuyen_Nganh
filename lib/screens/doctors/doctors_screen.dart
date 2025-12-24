// lib/screens/doctors/doctors_screen.dart

import 'package:flutter/material.dart';
import '../../models/medicine.dart'; // Giữ lại vì nó được import trong DataService
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'doctor_edit_screen.dart';
import 'doctor_registration_form.dart'; // Import Form đăng ký bác sĩ

class DoctorsScreen extends StatefulWidget {
  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  late Future<List<Map<String, dynamic>>> _doctorsFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'STT': 100.0,
    'HoTen': 300.0,
    'GioiTinh': 100.0,
    'NgaySinh': 120.0,
    'DienThoai': 170.0,
    'DiaChi': 250.0,
    'HoatDong': 200.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allDoctors = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _doctorsFuture = Future.value([]); // Khởi tạo mặc định
    _loadData();
  }

  void _loadData() async {
    try {
      // SỬA: Cần sửa hàm fetchDoctorsByRole trong DataService để lấy đủ trường
      final doctors = await _dataService.fetchDoctorsByRole('Bác sĩ'); // Đảm bảo gọi đúng tên vai trò

      if (mounted) {
        setState(() {
          _allDoctors = doctors;
          _doctorsFuture = Future.value(_filterDoctors(_allDoctors, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _doctorsFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ BÁC SĨ (Giữ nguyên)
  List<Map<String, dynamic>> _filterDoctors(List<Map<String, dynamic>> doctors, String query) {
    if (query.isEmpty) return doctors;
    final lowerCaseQuery = query.toLowerCase();

    return doctors.where((doctor) {
      return doctor['hovaten'].toLowerCase().contains(lowerCaseQuery) ||
            doctor['ngaysinh'].contains(lowerCaseQuery) ||
            doctor['sodienthoai'].toString().contains(lowerCaseQuery) == true;
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT (Giữ nguyên)
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _doctorsFuture = Future.value(_filterDoctors(_allDoctors, _searchQuery));
    });
  }


  // !!! HÀM XÓA USER (FIX CHỨC NĂNG)
  void _deleteDoctor(String authId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa tài khoản'),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản bác sĩ này vĩnh viễn? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _dataService.deleteUser(authId); // Gọi hàm xóa user
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa tài khoản bác sĩ thành công!'), backgroundColor: Colors.green));
          _loadData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: ${e.toString()}'), backgroundColor: Colors.red));
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
            SizedBox(width: _columnWidths['HoTen'], child: const Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['GioiTinh'], child: const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['NgaySinh'], child: const Text('Ngày sinh', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DienThoai'], child: const Text('Điện thoại', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DiaChi'], child: const Text('Địa chỉ', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hoạt động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(Map<String, dynamic> doctor, int index) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['HoTen'], child: Text(doctor['hovaten'] ?? 'N/A')),
            SizedBox(width: _columnWidths['GioiTinh'], child: Text(doctor['gioitinh'] ?? 'N/A')),
            SizedBox(width: _columnWidths['NgaySinh'], child: Text(doctor['ngaysinh'] ?? 'N/A')),
            SizedBox(width: _columnWidths['DienThoai'], child: Text(doctor['sodienthoai'] ?? 'N/A')),
            SizedBox(width: _columnWidths['DiaChi'], child: Text(doctor['diachi'] ?? 'N/A')),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                    onPressed: () async {
                      // !!! GỌI MÀN HÌNH CHỈNH SỬA
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => DoctorEditScreen(doctorAuthId: doctor['auth_id'], onSave: _loadData),
                      ));
                      _loadData();
                    },
                    tooltip: 'Chỉnh sửa'
                ),
                // !!! SỬ DỤNG HÀM DELETE MỚI VỚI auth_id
                IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteDoctor(doctor['auth_id']), tooltip: 'Xóa'),
              ],
            )),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/doctors';

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
                  const Text('DANH SÁCH BÁC SĨ PHÒNG KHÁM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  // Thanh tìm kiếm và Thêm mới
                  Row(
                    children: [
                      SizedBox(
                          width: 400,
                          child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Nhập tên , ngày sinh hoặc số điện thoại ',
                                border: OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              )
                          )

                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _performSearch, icon: const Icon(Icons.search), label: const Text('Tìm kiếm'), style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),),
                      const Spacer(),
                      ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => DoctorRegistrationForm(onSave: _loadData),
                            ));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Mời bác sĩ mới'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // HEADER BẢNG CỐ ĐỊNH
                  _buildFixedTableHeader(),

                  // Bảng dữ liệu CUỘN
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _doctorsFuture,
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
                        return const Center(child: Text('Không có bác sĩ nào trong phòng khám.'));
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