// lib/screens/medical_services/medical_service_edit_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../models/medical_service.dart';

class MedicalServiceEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final int serviceId;

  const MedicalServiceEditScreen({super.key, required this.onSave, required this.serviceId});

  @override
  _MedicalServiceEditScreenState createState() => _MedicalServiceEditScreenState();
}

class _MedicalServiceEditScreenState extends State<MedicalServiceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  late Future<MedicalService> _serviceFuture;

  String _tenDichVu = '';
  int _giaVND = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serviceFuture = _dataService.getMedicalServiceDetail(widget.serviceId);
  }

  void _submitForm(int currentId) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final success = await _dataService.updateMedicalService(currentId, _tenDichVu, _giaVND);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật dịch vụ thành công!'), backgroundColor: Colors.green));
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
           Sidebar(currentRoute: '/medical_services'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: FutureBuilder<MedicalService>(
                future: _serviceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));

                  final service = snapshot.data!;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHỈNH SỬA DỊCH VỤ KHÁM #${service.ma}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Divider(),

                        const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Mã dịch vụ (READ ONLY)
                        TextFormField(
                          initialValue: service.ma,
                          decoration:  InputDecoration(labelText: 'Mã Dịch Vụ', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[300]),
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // Tên dịch vụ (EDITABLE)
                        TextFormField(
                          initialValue: service.tendichvu,
                          decoration: const InputDecoration(labelText: 'Tên Dịch Vụ *', border: OutlineInputBorder()),
                          onSaved: (value) => _tenDichVu = value ?? '',
                          validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên dịch vụ' : null,
                        ),
                        const SizedBox(height: 20),

                        // Giá (EDITABLE)
                        TextFormField(
                          initialValue: service.giavnd.toString(),
                          decoration: const InputDecoration(labelText: 'Giá (VND)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _giaVND = int.tryParse(value ?? '0') ?? 0,
                          validator: (value) => value!.isEmpty || int.tryParse(value) == null ? 'Vui lòng nhập giá hợp lệ' : null,
                        ),
                        const SizedBox(height: 30),

                        // Nút hành động
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _submitForm(service.id),
                              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cập nhật'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue, foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // TODO: Thêm nút Xóa nếu cần
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