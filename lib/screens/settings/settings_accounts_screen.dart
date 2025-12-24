// lib/screens/settings/settings_accounts_screen.dart

import 'package:flutter/material.dart';
import '../../models/user_info.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'settings_user_role_edit_screen.dart'; // Import Form chỉnh sửa Vai trò
import 'staff_registration_form.dart'; // Import Form đăng ký nhân sự

class SettingsAccountsScreen extends StatefulWidget {
  @override
  _SettingsAccountsScreenState createState() => _SettingsAccountsScreenState();
}

class _SettingsAccountsScreenState extends State<SettingsAccountsScreen> {
  late Future<List<UserInfo>> _usersFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'HoTen': 200.0,
    'GioiTinh': 100.0,
    'NgaySinh': 150.0,
    'DienThoai': 150.0,
    'DiaChi': 250.0,
    'VaiTro': 200.0,
    'HoatDong': 200.0,
  };


  // Biến tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  List<UserInfo> _allUsers = [];
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _usersFuture = Future.value([]);
    _loadData();
  }
  // !!! HÀM SỬA: Xử lý nút Chỉnh sửa (điều hướng)
  void _openUserEditScreen(BuildContext context, UserInfo user) async {
    final bool? result = await Navigator.push(context, MaterialPageRoute(
      // Truyền UserInfo object
      builder: (context) => SettingsUserRoleEditScreen(user: user, onSave: _loadData),
    ));
    if (result == true) {
      _loadData(); // Tải lại danh sách nếu có thay đổi
    }
  }
  void _loadData() async {
    try {
      final users = await _dataService.fetchStaffList();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _usersFuture = Future.value(_filterUsers(_allUsers, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _usersFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ NHÂN SỰ
  List<UserInfo> _filterUsers(List<UserInfo> users, String query) {
    if (query.isEmpty) return users;
    final lowerCaseQuery = query.toLowerCase();

    return users.where((user) {
      return user.hovaten.toLowerCase().contains(lowerCaseQuery) ||
          user.sodienthoai.contains(lowerCaseQuery) ||
          user.role_name.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // XỬ LÝ TÌM KIẾM KHI NHẤN NÚT
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _usersFuture = Future.value(_filterUsers(_allUsers, _searchQuery));
    });
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
            SizedBox(width: _columnWidths['HoTen'], child: const Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['GioiTinh'], child: const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['NgaySinh'], child: const Text('Ngày sinh', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DienThoai'], child: const Text('Điện thoại', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['DiaChi'], child: const Text('Địa chỉ', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['VaiTro'], child: const Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hoạt động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(UserInfo user, int index) {
    final bool isAdmin = user.role_name == 'Admin';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['HoTen'], child: Text(user.hovaten)),
            SizedBox(width: _columnWidths['GioiTinh'], child: Text(user.gioitinh)),
            SizedBox(width: _columnWidths['NgaySinh'], child: Text(user.ngaysinh)),
            SizedBox(width: _columnWidths['DienThoai'], child: Text(user.sodienthoai)),
            SizedBox(width: _columnWidths['DiaChi'], child: Text(user.diachi)),
            SizedBox(width: _columnWidths['VaiTro'], child: Text(user.role_name)),
            SizedBox(width: _columnWidths['HoatDong'], child:
            // NÚT DROPDOWN ĐỔI VAI TRÒ
            // !!! NÚT CHỈNH SỬA VAI TRÒ
            ElevatedButton.icon(
              onPressed: isAdmin ? null : () => _openUserEditScreen(context, user),
              icon: Icon(Icons.edit, size: 18, color: isAdmin ? Colors.black54 : Colors.white),
              label: Text(isAdmin ? 'Admin' : 'Chỉnh sửa', style: TextStyle(color: isAdmin ? Colors.black54 : Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: isAdmin ? Colors.grey[300] : Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 35)
              ),
            )
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext setContext) {
    const String currentRoute = '/settings/accounts';

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
                  // THANH TIÊU ĐỀ VÀ HÀNH ĐỘNG CỐ ĐỊNH
                  Row(
                    children: [
                      const Text('QUẢN LÝ NHÂN SỰ PHÒNG KHÁM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Nút Mời nhân sự mới
                      ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(setContext, MaterialPageRoute(
                              builder: (context) => StaffRegistrationForm(onSave: _loadData),
                            ));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Mời nhân sự mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Thanh Tìm kiếm phụ
                  Row(
                    children: [
                      SizedBox(width: 300, child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Nhập họ tên nhân sự', border: OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)))),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(onPressed: _performSearch, icon: const Icon(Icons.search), label: const Text('Tìm kiếm'),style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // HEADER BẢNG CỐ ĐỊNH
                  _buildFixedTableHeader(),

                  // Bảng dữ liệu CUỘN DỌC
                  Expanded(
                    child: FutureBuilder<List<UserInfo>>(
                      future: _usersFuture,
                      builder: (BuildContext context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting ) return const Center(child: CircularProgressIndicator());
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
                        return const Center(child: Text('Không có tài khoản nào.'));
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