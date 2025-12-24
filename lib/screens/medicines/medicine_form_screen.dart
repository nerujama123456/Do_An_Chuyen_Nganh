// lib/screens/medicines/medicine_form_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../models/medicine_type.dart'; // Cần Model Loại thuốc

class MedicineFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const MedicineFormScreen({super.key, required this.onSave});

  @override
  _MedicineFormScreenState createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  String _tenThuoc = '';
  String _moTa = '';
  int _giaVND = 0;
  String _donViTinh = '';
  int? _selectedTypeId; // ID loại thuốc

  List<MedicineType> _typesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final types = await _dataService.fetchMedicineTypes();

      if (!mounted) return;

      setState(() {
        _typesList = types.map((map) => MedicineType.fromJson(map)).toList();
        if (_typesList.isNotEmpty) {
          _selectedTypeId = _typesList.first.id; // Chọn loại thuốc đầu tiên làm mặc định
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải loại thuốc: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final newMa = 'T${DateTime.now().millisecondsSinceEpoch}'; // Tự tạo Mã

        final success = await _dataService.createMedicine(newMa, _tenThuoc, _selectedTypeId!, _giaVND, _donViTinh, _moTa);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thuốc thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thuốc thất bại.'), backgroundColor: Colors.red));
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
           Sidebar(currentRoute: '/medicines'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÊM THUỐC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Hàng 1: Tên Thuốc, Loại Thuốc
                    Row(
                      children: [
                        Expanded(
                          // Tên thuốc
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Tên Thuốc *', border: OutlineInputBorder()),
                            onSaved: (value) => _tenThuoc = value ?? '',
                            validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên thuốc' : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          // Loại thuốc (Dropdown)
                          child: DropdownButtonFormField<int>(
                            value: _selectedTypeId,
                            decoration: const InputDecoration(labelText: 'Loại Thuốc *', border: OutlineInputBorder()),
                            items: _typesList.map((type) => DropdownMenuItem<int>(
                              value: type.id,
                              child: Text(type.tenloaithuoc),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedTypeId = value),
                            validator: (value) => value == null ? 'Vui lòng chọn loại thuốc' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Hàng 2: Giá, Đơn vị tính
                    Row(
                      children: [
                        Expanded(
                          // Giá
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Giá (VND) *', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            initialValue: '0',
                            onSaved: (value) => _giaVND = int.tryParse(value ?? '0') ?? 0,
                            validator: (value) => value!.isEmpty || int.tryParse(value) == null ? 'Vui lòng nhập giá hợp lệ' : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          // Đơn vị tính
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Đơn vị tính *', border: OutlineInputBorder()),
                            onSaved: (value) => _donViTinh = value ?? '',
                            validator: (value) => value!.isEmpty ? 'Vui lòng nhập đơn vị tính' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mô tả
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                      maxLines: 3,
                      onSaved: (value) => _moTa = value ?? '',
                        validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null
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