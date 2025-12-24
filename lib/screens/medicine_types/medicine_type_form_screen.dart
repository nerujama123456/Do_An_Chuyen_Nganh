// lib/screens/medicine_types/medicine_type_form_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';

class MedicineTypeFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const MedicineTypeFormScreen({super.key, required this.onSave});

  @override
  _MedicineTypeFormScreenState createState() => _MedicineTypeFormScreenState();
}

class _MedicineTypeFormScreenState extends State<MedicineTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  String _tenLoaiThuoc = '';
  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final newMa = 'LT${DateTime.now().millisecondsSinceEpoch}'; // Tự tạo Mã

        final success = await _dataService.createMedicineType(newMa, _tenLoaiThuoc);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm loại thuốc thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm loại thuốc thất bại.'), backgroundColor: Colors.red));
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
           Sidebar(currentRoute: '/medicine_types'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÊM LOẠI THUỐC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Tên loại thuốc
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Tên Loại Thuốc *', border: OutlineInputBorder()),
                      onSaved: (value) => _tenLoaiThuoc = value ?? '',
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên loại thuốc' : null,
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