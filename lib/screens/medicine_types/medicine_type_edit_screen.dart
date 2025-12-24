// lib/screens/medicine_types/medicine_type_edit_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../models/medicine_type.dart';

class MedicineTypeEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final int typeId;

  const MedicineTypeEditScreen({super.key, required this.onSave, required this.typeId});

  @override
  _MedicineTypeEditScreenState createState() => _MedicineTypeEditScreenState();
}

class _MedicineTypeEditScreenState extends State<MedicineTypeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  late Future<MedicineType> _typeFuture;

  String _tenLoaiThuoc = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _typeFuture = _dataService.getMedicineTypeDetail(widget.typeId);
  }

  void _submitForm(MedicineType type) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final success = await _dataService.updateMedicineType(type.id, _tenLoaiThuoc);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật loại thuốc thành công!'), backgroundColor: Colors.green));
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
           Sidebar(currentRoute: '/medicine_types'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: FutureBuilder<MedicineType>(
                future: _typeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));

                  final type = snapshot.data!;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHỈNH SỬA LOẠI THUỐC #${type.ma}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Divider(),

                        const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Mã loại thuốc (READ ONLY)
                        TextFormField(
                          initialValue: type.ma,
                          decoration:  InputDecoration(labelText: 'Mã Loại Thuốc', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[300]),
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // Tên loại thuốc (EDITABLE)
                        TextFormField(
                          initialValue: type.tenloaithuoc,
                          decoration: const InputDecoration(labelText: 'Tên Loại Thuốc *', border: OutlineInputBorder()),
                          onSaved: (value) => _tenLoaiThuoc = value ?? '',
                          validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên loại thuốc' : null,
                        ),
                        const SizedBox(height: 30),

                        // Nút hành động
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _submitForm(type),
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