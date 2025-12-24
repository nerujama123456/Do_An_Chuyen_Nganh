// lib/screens/patients/patients_screen.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import '../appointments/appointment_form_screen.dart';
import 'patient_form_screen.dart';
import 'patient_edit_screen.dart';

class PatientsScreen extends StatefulWidget {
  @override
  _PatientsScreenState createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  late Future<List<Patient>> _patientsFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'STT': 50.0,
    'Ma': 200.0,
    'HoTen': 250.0,
    'GioiTinh': 100.0,
    'SoDienThoai': 150.0,
    'NgaySinh': 100.0,
    'DiaChi': 250.0,
    'HoatDong': 150.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _allPatients = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _patientsFuture = Future.value([]);
    _loadData();
  }

  void _loadData() async {
    try {
      final maps = await _dataService.fetchPatients();
      final patients = maps.map((map) => Patient.fromJson(map)).toList();

      if (mounted) {
        setState(() {
          _allPatients = patients;
          _patientsFuture = Future.value(_filterPatients(_allPatients, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _patientsFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ BỆNH NHÂN
  List<Patient> _filterPatients(List<Patient> patients, String query) {
    if (query.isEmpty) {
      return patients;
    }
    final lowerCaseQuery = query.toLowerCase();

    return patients.where((patient) {
      return patient.ma.toLowerCase().contains(lowerCaseQuery) ||
          patient.hovaten.toLowerCase().contains(lowerCaseQuery) ||
          patient.gioitinh.toLowerCase().contains(lowerCaseQuery) ||
          patient.sodienthoai.contains(lowerCaseQuery) ||
          patient.ngaysinh.contains(lowerCaseQuery) ||
          patient.diachi.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _patientsFuture = Future.value(_filterPatients(_allPatients, _searchQuery));
    });
  }


  void _deletePatient(int patientId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hồ sơ bệnh nhân này? (Toàn bộ lịch hẹn, đơn thuốc, giấy khám bệnh sẽ bị xóa)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _dataService.deletePatientAndRecords(patientId);

        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa bệnh nhân và các hồ sơ liên quan thành công!'), backgroundColor: Colors.green));
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại (Lỗi không xác định).'), backgroundColor: Colors.red));
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
            SizedBox(width: _columnWidths['HoTen'], child: const Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['GioiTinh'], child: const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['SoDienThoai'], child: const Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['NgaySinh'], child: const Text('Ngày sinh', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DiaChi'], child: const Text('Địa chỉ', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(Patient patient, int index) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(patient.ma)),
            SizedBox(width: _columnWidths['HoTen'], child: Text(patient.hovaten)),
            SizedBox(width: _columnWidths['GioiTinh'], child: Text(patient.gioitinh)),
            SizedBox(width: _columnWidths['SoDienThoai'], child: Text(patient.sodienthoai)),
            SizedBox(width: _columnWidths['NgaySinh'], child: Text(patient.ngaysinh)),
            SizedBox(width: _columnWidths['DiaChi'], child: Text(patient.diachi)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(children: [
              // Nút Chỉnh sửa
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => PatientEditScreen(patientId: patient.id, onSave: _loadData),
                    ));
                    _loadData();
                  },
                  tooltip: 'Chỉnh sửa'
              ),
              // Nút Xóa
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deletePatient(patient.id), tooltip: 'Xóa'),
            ])),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/patients';

    return Scaffold(
      body: Row(
        children: <Widget>[
          Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column( // Column chính chứa Fixed Header
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('DANH SÁCH BỆNH NHÂN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  // THANH TÌM KIẾM
                  Row(
                    children: [
                      SizedBox(
                          width: 300,
                          child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Nhập họ và tên',
                                border: OutlineInputBorder(),
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



                      // Nút Thêm bệnh nhân
                      ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => PatientFormScreen(onSave: _loadData),
                            ));
                            _loadData();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm bệnh nhân'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // HEADER BẢNG CỐ ĐỊNH
                  _buildFixedTableHeader(),

                  // Bảng dữ liệu CUỘN DỌC
                  Expanded(
                    child: FutureBuilder<List<Patient>>(
                      future: _patientsFuture,
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
                        return const Center(child: Text('Không có bệnh nhân nào.'));
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