// lib/screens/patients/patient_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';

class PatientFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const PatientFormScreen({super.key, required this.onSave});

  @override
  _PatientFormScreenState createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  String _hoVaTen = '';
  String _gioiTinh = 'Nam'; // Giá trị mặc định
  String _soDienThoai = '';
  String _diaChi = '';
  DateTime? _ngaySinh;

  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final newMa = 'BN${DateTime.now().millisecondsSinceEpoch}'; // Tự tạo Mã

        final data = {
          'ma': newMa,
          'hovaten': _hoVaTen,
          'gioitinh': _gioiTinh,
          'sodienthoai': _soDienThoai,
          'diachi': _diaChi,
          'ngaysinh': _ngaySinh?.toIso8601String().substring(0, 10),
        };

        final success = await _dataService.createPatient(data);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave(); // Tải lại danh sách
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm bệnh nhân thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm bệnh nhân thất bại.'), backgroundColor: Colors.red));
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
    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/patients'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÊM BỆNH NHÂN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Hàng 1: Họ và tên, Ảnh đại diện
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Họ và tên *', border: OutlineInputBorder()),
                          onSaved: (value) => _hoVaTen = value ?? '',
                          validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 20),

                    ]),
                    const SizedBox(height: 20),

                    // Hàng 2: Giới tính, Số điện thoại
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Giới tính *', style: TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Radio<String>(value: 'Nam', groupValue: _gioiTinh, onChanged: (v) => setState(() => _gioiTinh = v!)),
                                const Text('Nam'),
                                Radio<String>(value: 'Nữ', groupValue: _gioiTinh, onChanged: (v) => setState(() => _gioiTinh = v!)),
                                const Text('Nữ'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Số điện thoại *', border: OutlineInputBorder()),
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => _soDienThoai = value ?? '',
                          validator: (value) => value!.isEmpty || value.length<10 || value.length>10 ? 'Vui lòng nhập đủ 10 chữ số điện thoại' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Hàng 3: Ngày sinh, Địa chỉ
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(text: _ngaySinh == null ? 'Chọn ngày sinh' : DateFormat('dd-MM-yyyy').format(_ngaySinh!)),
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                            if (date != null) setState(() => _ngaySinh = date);
                          },
                          decoration: const InputDecoration(labelText: 'Ngày sinh *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                          validator: (value) => _ngaySinh == null ? 'Trường bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Địa chỉ *', border: OutlineInputBorder()),
                          onSaved: (value) => _diaChi = value ?? '',
                          validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 30),

                    // Nút hành động
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Quay lại'),
                        ),
                      ],
                    ),
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