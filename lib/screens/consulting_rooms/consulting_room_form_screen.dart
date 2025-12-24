// lib/screens/consulting_rooms/consulting_room_form_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';

class ConsultingRoomFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const ConsultingRoomFormScreen({super.key, required this.onSave});

  @override
  _ConsultingRoomFormScreenState createState() => _ConsultingRoomFormScreenState();
}

class _ConsultingRoomFormScreenState extends State<ConsultingRoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  String _ma = '';
  String _tenPhongKham = '';
  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final newMa = 'PK${DateTime.now().millisecondsSinceEpoch}'; // Tự tạo Mã

        final success = await _dataService.createConsultingRoom(newMa, _tenPhongKham);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave(); // Tải lại danh sách
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm phòng khám thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm phòng khám thất bại.'), backgroundColor: Colors.red));
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
           Sidebar(currentRoute: '/consulting_rooms'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÊM PHÒNG KHÁM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Tên phòng khám
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Tên Phòng Khám *', border: OutlineInputBorder()),
                      onSaved: (value) => _tenPhongKham = value ?? '',
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên phòng khám' : null,
                    ),
                    const SizedBox(height: 30),

                    // Nút hành động
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu lại'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)

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