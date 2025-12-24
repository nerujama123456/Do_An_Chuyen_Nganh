// lib/screens/patients/patient_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../models/patient.dart';

class PatientEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final int patientId;

  const PatientEditScreen({super.key, required this.onSave, required this.patientId});

  @override
  _PatientEditScreenState createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  late Future<Patient> _patientFuture;

  String _hoVaTen = '';
  String _gioiTinh = '';
  String _soDienThoai = '';
  String _diaChi = '';
  DateTime? _ngaySinh;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _patientFuture = _dataService.getPatientDetail(widget.patientId);
  }

  // Hàm gán dữ liệu từ Patient Model sang State variables
  void _assignInitialData(Patient patient) {
    _hoVaTen = patient.hovaten;
    _gioiTinh = patient.gioitinh;
    _soDienThoai = patient.sodienthoai;
    _diaChi = patient.diachi;
    _ngaySinh = DateTime.tryParse(patient.ngaysinh);

  }


  void _submitForm(int currentId) async {
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
        };

        final success = await _dataService.updatePatient(currentId, data);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave(); // Tải lại danh sách
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật bệnh nhân thành công!'), backgroundColor: Colors.green));
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
    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/patients'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: FutureBuilder<Patient>(
                future: _patientFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));

                  final patient = snapshot.data!;
                  _assignInitialData(patient); // Gán dữ liệu ban đầu

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CẬP NHẬT BỆNH NHÂN #${patient.ma}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Divider(),

                        const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Hàng 1: Họ và tên, Ảnh đại diện
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _hoVaTen,
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
                                Row(children: [
                                  Radio<String>(value: 'Nam', groupValue: _gioiTinh, onChanged: (v) => setState(() => _gioiTinh = v!)),
                                  const Text('Nam'),
                                  Radio<String>(value: 'Nữ', groupValue: _gioiTinh, onChanged: (v) => setState(() => _gioiTinh = v!)),
                                  const Text('Nữ'),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              initialValue: _soDienThoai,
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
                                final date = await showDatePicker(context: context, initialDate: _ngaySinh ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                                if (date != null) setState(() => _ngaySinh = date);
                              },
                              decoration: const InputDecoration(labelText: 'Ngày sinh *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                              validator: (value) => _ngaySinh == null ? 'Trường bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              initialValue: _diaChi,
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
                              onPressed: _isLoading ? null : () => _submitForm(patient.id),
                              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cập nhật'),
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}