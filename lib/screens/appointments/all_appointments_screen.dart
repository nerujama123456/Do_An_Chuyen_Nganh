// lib/screens/appointments/all_appointments_screen.dart

import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'appointment_form_screen.dart';

class AllAppointmentsScreen extends StatefulWidget {
  @override
  _AllAppointmentsScreenState createState() => _AllAppointmentsScreenState();
}

class _AllAppointmentsScreenState extends State<AllAppointmentsScreen> {
  late Future<List<Appointment>> _appointmentsFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột (Đã tinh chỉnh)
  final Map<String, double> _columnWidths = const {
    'NgayHen': 100.0,
    'GioHen': 80.0,
    'MaLH': 150.0,
    'HoTen': 200.0,
    'GioiTinh': 100.0,
    'DienThoai': 150.0,
    'BacSi': 190.0,
    'TrangThai': 150.0,
    'HoatDong': 150.0,
  };

  // BIẾN TÌM KIẾM VÀ DANH SÁCH GỐC
  final TextEditingController _searchController = TextEditingController();
  List<Appointment> _allAppointments = [];
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _appointmentsFuture = Future.value([]);
    _loadData();
  }

  void _loadData() async {
    try {
      // !!! GỌI HÀM FETCH TẤT CẢ
      final appointments = await _dataService.fetchAllAppointments();

      if (mounted) {
        setState(() {
          _allAppointments = appointments;
          _appointmentsFuture = Future.value(_filterAppointments(_allAppointments, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _appointmentsFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ
  List<Appointment> _filterAppointments(List<Appointment> appointments, String query) {
    if (query.isEmpty) {
      return appointments;
    }
    final lowerCaseQuery = query.toLowerCase();

    return appointments.where((app) {
      return app.ngaydathen.contains(lowerCaseQuery) ||
          app.giodathen.contains(lowerCaseQuery) ||
          app.patient_id.toString().contains(lowerCaseQuery) ||
          app.hovaten.toLowerCase().contains(lowerCaseQuery) ||
          app.gioitinh.toLowerCase().contains(lowerCaseQuery) ||
          app.sodienthoai.contains(lowerCaseQuery) ||
          app.bacsi.toLowerCase().contains(lowerCaseQuery);
    }).toList();
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
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _appointmentsFuture = Future.value(_filterAppointments(_allAppointments, _searchQuery));
    });
  }

  void _confirmAppointment(String appointmentId) async {
    final success = await _dataService.confirmAppointment(appointmentId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác nhận lịch hẹn thành công!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác nhận thất bại. Lịch hẹn có thể đã được xác nhận.'), backgroundColor: Colors.red));
      }
      _loadData();
    }
  }

  void _deleteAppointment(String appointmentId) async {
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
        await _dataService.deleteAppointment(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa lịch hẹn thành công!'), backgroundColor: Colors.green));
          _loadData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
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
            SizedBox(width: _columnWidths['NgayHen'], child: const Text('Ngày hẹn', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['GioHen'], child: const Text('Giờ hẹn', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['MaLH'], child: const Text('Mã LH', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoTen'], child: const Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['GioiTinh'], child: const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DienThoai'], child: const Text('Điện thoại', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['BacSi'], child: const Text('Bác sĩ khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TrangThai'], child: const Text('Trạng thái khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hoạt động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // PHẦN CUỘN: Một hàng dữ liệu
  Widget _buildDataRow(Appointment appointment) {
    final isPending = appointment.trangthai == 'Chờ xác nhận';
    final Color statusColor = appointment.trangthai == 'Đã xác nhận khám' ? Colors.green : Colors.red;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['NgayHen'], child: Text(appointment.ngaydathen)),
            SizedBox(width: _columnWidths['GioHen'], child: Text(appointment.giodathen)),
            SizedBox(width: _columnWidths['MaLH'], child: Text(appointment.ma)),
            SizedBox(width: _columnWidths['HoTen'], child: Text(appointment.hovaten)),
            SizedBox(width: _columnWidths['GioiTinh'], child: Text(appointment.gioitinh)),
            SizedBox(width: _columnWidths['DienThoai'], child: Text(appointment.sodienthoai)),
            SizedBox(width: _columnWidths['BacSi'], child: Text(appointment.bacsi ?? 'N/A')),
            SizedBox(width: _columnWidths['TrangThai'], child: _buildStatusButton(appointment.trangthai, statusColor)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(
              children: [
                // Nút Xác nhận Khám (✓) - CHỈ HIỂN THỊ KHI 'Chờ xác nhận'

                if (isPending)

                  IconButton(

                    icon: const Icon(Icons.done_all, color: Colors.green, size: 20),
                    onPressed: () => _confirmAppointment(appointment.id),
                    tooltip: 'Xác nhận Khám',
                    padding: EdgeInsets.zero
                  ),

                // NÚT XÓA
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteAppointment(appointment.id),
                  tooltip: 'Xóa lịch hẹn',
                  padding: EdgeInsets.zero
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  // HÀM TẠO THANH TÌM KIẾM VÀ ĐẶT HẸN
  Widget _buildSearchAndActionButton(BuildContext context) {
    return Row(
      children: [
        // Ô TÌM KIẾM
        SizedBox(
            width: 300,
            child: TextField(
                controller: _searchController, // Controller cho tìm kiếm
                decoration: InputDecoration(
                  hintText: 'Nhập họ và tên',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                )
            )
        ),
        const SizedBox(width: 10),
        // NÚT TÌM KIẾM
        ElevatedButton.icon(
            onPressed: _performSearch, // Gọi hàm tìm kiếm
            icon: const Icon(Icons.search),
            label: const Text('Tìm kiếm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
        ),
        const Spacer(),
        // Nút ĐẶT HẸN (Giống trang Bệnh nhân)
        ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (context) => AppointmentFormScreen(onSave: _loadData),
              ));
              _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Đặt hẹn'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/all_appointments'; // Thay đổi route hiện tại

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
                  // PHẦN CỐ ĐỊNH 1: TIÊU ĐỀ TRANG
                  const Text('DANH SÁCH TẤT CẢ LỊCH HẸN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  // PHẦN TÌM KIẾM VÀ ĐẶT HẸN MỚI
                  _buildSearchAndActionButton(context),
                  const SizedBox(height: 15),

                  // PHẦN CỐ ĐỊNH 2: HEADER BẢNG
                  _buildFixedTableHeader(),

                  // PHẦN CUỘN: LIST DỮ LIỆU
                  Expanded( // LISTVIEW CUỘN DỌC
                    child: FutureBuilder<List<Appointment>>(
                      future: _appointmentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          // ListView.separated để cuộn dọc và thêm đường kẻ
                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return _buildDataRow(snapshot.data![index]);
                            },
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                          );
                        }
                        return const Center(child: Text('Không có lịch hẹn nào.'));
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