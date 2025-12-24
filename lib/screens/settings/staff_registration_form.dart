// lib/screens/settings/staff_registration_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';

class StaffRegistrationForm extends StatefulWidget {
  final VoidCallback onSave;

  const StaffRegistrationForm({super.key, required this.onSave});

  @override
  _StaffRegistrationFormState createState() => _StaffRegistrationFormState();
}

class _StaffRegistrationFormState extends State<StaffRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();

  // Biến trạng thái Form
  String _hoVaTen = '';
  String _email = '';
  String _password = '';
  String _gioiTinh = 'Nam';
  String _soDienThoai = '';
  String _diaChi = '';
  DateTime? _ngaySinh;
  int? _selectedRoleId;

  List<Map<String, dynamic>> _rolesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  void _loadRoles() async {
    try {
      final roles = await _dataService.fetchRoles();
      if (!mounted) return;
      setState(() {
        // Lọc Admin ra khỏi danh sách
        _rolesList = roles.where((r) => r['tenvaitro'] != 'Admin').toList();
        if (_rolesList.isNotEmpty) {
          _selectedRoleId = _rolesList.first['id'] as int;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final data = {
          'hovaten': _hoVaTen,
          'gioitinh': _gioiTinh,
          'sodienthoai': _soDienThoai,
          'diachi': _diaChi,
          'ngaysinh': _ngaySinh?.toIso8601String().substring(0, 10),
          'role_id': _selectedRoleId,
        };

        final String? errorMessage = await _authService.registerNewStaff(_email, _password, data);

        if (mounted) {
          setState(() => _isLoading = false);
          if (errorMessage == null) {

            // !!! HÀNH ĐỘNG MỚI: ĐĂNG XUẤT ADMIN VÀ CHUYỂN VỀ LOGIN
            await _authService.signOut();

            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký nhân sự thành công!'), backgroundColor: Colors.green));

            // Chuyển hướng cứng về màn hình đăng nhập
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng ký thất bại: $errorMessage'), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: ${e.toString()}'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/settings/accounts'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MỜI NHÂN SỰ MỚI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin đăng nhập & hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Hàng Email/Password
                    Row(children: [
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()), onSaved: (v) => _email = v ?? '', validator: (v) => v!.isEmpty || !v.contains('@') ? 'Email không hợp lệ' : null)),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu *', border: OutlineInputBorder()), onSaved: (v) => _password = v ?? '', validator: (v) => v!.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null)),
                    ]),
                    const SizedBox(height: 20),

                    // Hàng Họ tên / Vai trò
                    Row(children: [
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Họ và tên *', border: OutlineInputBorder()), onSaved: (v) => _hoVaTen = v ?? '', validator: (v) => v!.isEmpty ? 'Trường bắt buộc' : null)),
                      const SizedBox(width: 20),
                      Expanded(child: DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        decoration: const InputDecoration(labelText: 'Vai trò *', border: OutlineInputBorder()),
                        items: _rolesList.map((role) => DropdownMenuItem<int>(value: role['id'] as int, child: Text(role['tenvaitro']))).toList(),
                        onChanged: (v) => setState(() => _selectedRoleId = v),
                        validator: (v) => v == null ? 'Chọn vai trò' : null,
                        onSaved: (v) => _selectedRoleId = v,
                      )),
                    ]),
                    const SizedBox(height: 20),

                    // Hàng Giới tính / Ngày sinh / SĐT
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Giới tính *', style: TextStyle(fontWeight: FontWeight.bold)),
                            Row(children: [
                              Radio<String>(value: 'Nam', groupValue: _gioiTinh, onChanged: (v) => setState(() => _gioiTinh = v!)), const Text('Nam'),
                              Radio<String>(value: 'Nữ', groupValue: _gioiTinh, onChanged: (v) => setState(() => _gioiTinh = v!)), const Text('Nữ'),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(readOnly: true, controller: TextEditingController(text: _ngaySinh == null ? 'Chọn ngày sinh' : DateFormat('dd-MM-yyyy').format(_ngaySinh!)), onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                        if (date != null) setState(() => _ngaySinh = date);
                      }, decoration: const InputDecoration(labelText: 'Ngày sinh', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), onSaved: (v){})),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()), keyboardType: TextInputType.phone, onSaved: (v) => _soDienThoai = v ?? '',validator: (value) => value!.isEmpty || value.length<10 || value.length>10 ? 'Vui lòng nhập đủ 10 chữ số điện thoại' : null)),
                    ]),
                    const SizedBox(height: 20),

                    // Địa chỉ
                    TextFormField(decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()), maxLines: 2, onSaved: (v) => _diaChi = v ?? '',validator: (value) => value!.isEmpty  ? 'Trường bắt buộc' : null,),
                    const SizedBox(height: 30),

                    // Nút hành động
                    Row(children: [
                      ElevatedButton(onPressed: _isLoading ? null : _submitForm, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đăng ký'),style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),),
                      const SizedBox(width: 10),
                      OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}