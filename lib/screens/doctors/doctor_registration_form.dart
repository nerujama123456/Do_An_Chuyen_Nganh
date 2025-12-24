// lib/screens/doctors/doctor_registration_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';

class DoctorRegistrationForm extends StatefulWidget {
  final VoidCallback onSave;

  const DoctorRegistrationForm({super.key, required this.onSave});

  @override
  _DoctorRegistrationFormState createState() => _DoctorRegistrationFormState();
}

class _DoctorRegistrationFormState extends State<DoctorRegistrationForm> {
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

  bool _isLoading = true; // Bắt đầu là true để chờ loadRoleId
  int? _doctorId; // ID Vai trò Bác sĩ


  @override
  void initState() {
    super.initState();
    _loadRoleId();
  }

  void _loadRoleId() async {
    try {
      // Tìm ID của vai trò Bác sĩ
      final roles = await _dataService.fetchRoles();
      // Sử dụng where an toàn hơn
      final doctorRole = roles.firstWhere((r) => r['tenvaitro'] == 'Bác sĩ', orElse: () => {});

      if (mounted) {
        setState(() {
          // Gán ID nếu tìm thấy, nếu không, nó vẫn là null
          _doctorId = doctorRole['id'] as int?;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Nếu lỗi tải roles, vẫn set isLoading = false
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải dữ liệu vai trò.'), backgroundColor: Colors.red));
      }
    }
  }

  void _submitForm() async {
    // !!! KIỂM TRA ĐỒNG THỜI FORM VÀ ID
    if (!_formKey.currentState!.validate() || _doctorId == null) {
      if (_doctorId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Không tìm thấy ID vai trò Bác sĩ trong DB.'), backgroundColor: Colors.red));
      }
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final data = {
        'hovaten': _hoVaTen,
        'gioitinh': _gioiTinh,
        'sodienthoai': _soDienThoai,
        'diachi': _diaChi,
        'ngaysinh': _ngaySinh?.toIso8601String().substring(0, 10),
        'role_id': _doctorId, // Gán cố định vai trò Bác sĩ
      };

      final String? errorMessage = await _authService.registerNewStaff(_email, _password, data);

      if (mounted) {
        setState(() => _isLoading = false);
        if (errorMessage == null) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký bác sĩ thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/doctors'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MỜI BÁC SĨ MỚI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                      Expanded(child: TextFormField(
                        // Hiển thị Vai trò và bôi xám
                        initialValue: 'Bác sĩ',
                        decoration: InputDecoration(labelText: 'Vai trò (Cố định)', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[200]),
                        readOnly: true,
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
                      }, decoration: const InputDecoration(labelText: 'Ngày sinh *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),validator: (value) =>  _ngaySinh == null ? 'Trường bắt buộc' : null)),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()), keyboardType: TextInputType.phone, onSaved: (v) => _soDienThoai = v ?? '',validator: (value) => value!.isEmpty || value.length<10 || value.length>10 ? 'Vui lòng nhập đủ 10 chữ số điện thoại' : null)),
                    ]),
                    const SizedBox(height: 20),

                    // Địa chỉ
                    TextFormField(decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()), maxLines: 2, onSaved: (v) => _diaChi = v ?? '',validator: (value) =>  value!.isEmpty ? 'Trường bắt buộc' : null),
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