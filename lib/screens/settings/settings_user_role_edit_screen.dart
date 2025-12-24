// lib/screens/settings/settings_user_role_edit_screen.dart

import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import '../../models/user_info.dart';

class SettingsUserRoleEditScreen extends StatefulWidget {
  final UserInfo user;
  final VoidCallback onSave;

  const SettingsUserRoleEditScreen({super.key, required this.user, required this.onSave});

  @override
  _SettingsUserRoleEditScreenState createState() => _SettingsUserRoleEditScreenState();
}

class _SettingsUserRoleEditScreenState extends State<SettingsUserRoleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  late Future<List<Map<String, dynamic>>> _rolesFuture;
  int? _selectedRoleId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rolesFuture = _dataService.fetchRoles();
    _selectedRoleId = widget.user.role_id; // Giá trị mặc định là vai trò hiện tại
  }

  void _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final success = await _dataService.updateUserRole(widget.user.auth_id, _selectedRoleId!);

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật vai trò thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context, true);
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
    // Không cho phép sửa nếu là Admin
    final bool isAdmin = widget.user.role_name == 'Admin';
    final String currentTitle = 'PHÂN QUYỀN: ${widget.user.hovaten.toUpperCase()}';

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/settings/accounts'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _rolesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting || _isLoading) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Lỗi tải vai trò: ${snapshot.error}'));

                  final roles = snapshot.data!;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Divider(),

                        // Hiển thị vai trò hiện tại
                        Text('Vai trò hiện tại: ${widget.user.role_name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),

                        // Dropdown chọn Vai trò mới
                        DropdownButtonFormField<int>(
                          value: _selectedRoleId,
                          decoration: InputDecoration(
                            labelText: isAdmin ? 'Không thể chỉnh sửa (Admin)' : 'Chọn Vai trò mới *',
                            border: const OutlineInputBorder(),
                            filled: isAdmin, // Bôi xám nếu là Admin
                            fillColor: isAdmin ? Colors.grey[200] : Colors.white,
                          ),
                          items: roles.map((role) => DropdownMenuItem<int>(
                            value: role['id'] as int,
                            child: Text(role['tenvaitro']),
                          )).toList(),
                          onChanged: isAdmin ? null : (value) => setState(() => _selectedRoleId = value),
                          validator: (value) => value == null ? 'Vui lòng chọn vai trò' : null,
                          isExpanded: true,
                        ),

                        const SizedBox(height: 30),

                        // Nút hành động
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: (isAdmin || _isLoading) ? null : _submitUpdate,
                              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cập nhật vai trò'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
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