// lib/screens/doctors/doctor_edit_screen.dart (File MỚI)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../models/user_info.dart';

class DoctorEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final String doctorAuthId;

  const DoctorEditScreen({super.key, required this.onSave, required this.doctorAuthId});

  @override
  _DoctorEditScreenState createState() => _DoctorEditScreenState();
}

class _DoctorEditScreenState extends State<DoctorEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  // Biến trạng thái Form
  String _hoVaTen = '';
  String _gioiTinh = 'Nam';
  String _soDienThoai = '';
  String _diaChi = '';
  DateTime? _ngaySinh;
  String _currentRoleName = '';

  bool _isLoading = true;

  // Controllers (Bắt buộc để giữ giá trị ban đầu và edit)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final DateFormat formatter = DateFormat('dd-MM-yyyy');


  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Xử lý Dispose Controllers
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }


  void _loadInitialData() async {
    try {
      // Lấy thông tin hồ sơ bác sĩ
      final userInfoMap = await _dataService.getUserProfile(widget.doctorAuthId);

      if (!mounted) return;

      final UserInfo user = UserInfo.fromJson(userInfoMap);

      setState(() {
        _hoVaTen = user.hovaten;
        _gioiTinh = user.gioitinh;
        _soDienThoai = user.sodienthoai;
        _diaChi = user.diachi;
        _ngaySinh = DateTime.tryParse(user.ngaysinh);
        _currentRoleName = user.role_name;

        // Gán giá trị vào Controllers
        _nameController.text = _hoVaTen;
        _phoneController.text = _soDienThoai;
        _addressController.text = _diaChi;

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
        setState(() => _isLoading = false);
      }
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
          // KHÔNG GỬI role_id
        };

        // Gọi hàm UPDATE hồ sơ
        final success = await _dataService.updateDoctorProfile(widget.doctorAuthId, data);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại.'), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
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
           Sidebar(currentRoute: '/doctors'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHỈNH SỬA HỒ SƠ BÁC SĨ #${_hoVaTen.toUpperCase()}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Hàng 1: Họ và tên / Vai trò (READ ONLY)
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Họ và tên *', border: OutlineInputBorder()),
                          onSaved: (v) => _hoVaTen = v ?? '',
                          validator: (v) => v!.isEmpty ? 'Trường bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                          child: TextFormField(
                            initialValue: _currentRoleName,
                            decoration: InputDecoration(labelText: 'Vai trò', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[200]),
                            readOnly: true, // KHÔNG CHO PHÉP SỬA VAI TRÒ
                          )
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Hàng 2: Giới tính / Ngày sinh / SĐT
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
                      Expanded(child: TextFormField(readOnly: true, controller: TextEditingController(text: _ngaySinh == null ? 'Chọn ngày sinh' : formatter.format(_ngaySinh!)), onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: _ngaySinh ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                        if (date != null) setState(() => _ngaySinh = date);
                      }, decoration: const InputDecoration(labelText: 'Ngày sinh *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),validator: (value) => value!.isEmpty || value.length<10 || value.length>10 ? 'Vui lòng nhập đủ 10 chữ số điện thoại' : null)),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()), keyboardType: TextInputType.phone, onSaved: (v) => _soDienThoai = v ?? '')),
                    ]),
                    const SizedBox(height: 20),

                    // Địa chỉ
                    TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()), maxLines: 2, onSaved: (v) => _diaChi = v ?? ''),
                    const SizedBox(height: 30),

                    // Nút hành động
                    Row(children: [
                      ElevatedButton(onPressed: _isLoading ? null : _submitForm, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cập nhật'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)),
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