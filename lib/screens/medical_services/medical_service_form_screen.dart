// lib/screens/medical_services/medical_service_form_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart'; // Dùng DataService cho CRUD danh mục

class MedicalServiceFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const MedicalServiceFormScreen({super.key, required this.onSave});

  @override
  _MedicalServiceFormScreenState createState() => _MedicalServiceFormScreenState();
}

class _MedicalServiceFormScreenState extends State<MedicalServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  String _tenDichVu = '';
  int _giaVND = 0;
  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        // Mã dịch vụ tự tạo
        final newMa = 'DV${DateTime.now().millisecondsSinceEpoch}';

        final success = await _dataService.createMedicalService(newMa, _tenDichVu, _giaVND);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave(); // Tải lại danh sách
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm dịch vụ thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm dịch vụ thất bại.'), backgroundColor: Colors.red));
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
           Sidebar(currentRoute: '/medical_services'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÊM DỊCH VỤ KHÁM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Tên dịch vụ
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Tên Dịch Vụ *', border: OutlineInputBorder()),
                      onSaved: (value) => _tenDichVu = value ?? '',
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên dịch vụ' : null,
                    ),
                    const SizedBox(height: 20),

                    // Giá
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Giá (VND)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      initialValue: '0',
                      onSaved: (value) => _giaVND = int.tryParse(value ?? '0') ?? 0,
                      validator: (value) => value!.isEmpty || int.tryParse(value) == null ? 'Vui lòng nhập giá hợp lệ' : null,
                    ),
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