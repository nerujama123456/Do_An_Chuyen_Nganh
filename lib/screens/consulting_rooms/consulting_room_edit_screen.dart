// lib/screens/consulting_rooms/consulting_room_edit_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../models/consulting_room.dart';

class ConsultingRoomEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final int roomId;

  const ConsultingRoomEditScreen({super.key, required this.onSave, required this.roomId});

  @override
  _ConsultingRoomEditScreenState createState() => _ConsultingRoomEditScreenState();
}

class _ConsultingRoomEditScreenState extends State<ConsultingRoomEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  late Future<ConsultingRoom> _roomFuture;

  String _ma = '';
  String _tenPhongKham = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roomFuture = _dataService.getConsultingRoomDetail(widget.roomId);
  }

  void _submitForm(ConsultingRoom room) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final success = await _dataService.updateConsultingRoom(room.id, _tenPhongKham);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave(); // Tải lại danh sách
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật phòng khám thành công!'), backgroundColor: Colors.green));
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
           Sidebar(currentRoute: '/consulting_rooms'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: FutureBuilder<ConsultingRoom>(
                future: _roomFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));

                  final room = snapshot.data!;
                  _ma = room.ma; // Gán Mã phòng khám

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHỈNH SỬA PHÒNG KHÁM #${room.ma}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Divider(),

                        const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Mã phòng khám (READ ONLY)
                        TextFormField(
                          initialValue: room.ma,
                          decoration:  InputDecoration(labelText: 'Mã Phòng Khám', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[300]),
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // Tên phòng khám (EDITABLE)
                        TextFormField(
                          initialValue: room.tenphongkham,
                          decoration: const InputDecoration(labelText: 'Tên Phòng Khám *', border: OutlineInputBorder()),
                          onSaved: (value) => _tenPhongKham = value ?? '',
                          validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên phòng khám' : null,
                        ),
                        const SizedBox(height: 30),

                        // Nút hành động
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _submitForm(room),
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