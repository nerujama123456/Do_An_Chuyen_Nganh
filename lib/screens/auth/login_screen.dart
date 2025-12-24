// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _supabaseService = AuthService();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final result = await _supabaseService.signIn(_email, _password);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result == null) {
          // Đăng nhập thành công, chuyển đến trang danh sách
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Lỗi xác thực
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)]
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Chào mừng trở lại!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Đăng nhập để tiếp tục', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // Email
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nhập email', border: OutlineInputBorder()),
                  onSaved: (value) => _email = value!.trim(),
                  validator: (value) => value!.isEmpty ? 'Email không được để trống' : null,
                ),
                const SizedBox(height: 20),

                // Mật khẩu
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nhập mật khẩu', border: OutlineInputBorder()),
                  onSaved: (value) => _password = value!,
                  validator: (value) => value!.isEmpty ? 'Mật khẩu không được để trống' : null,
                ),
                const SizedBox(height: 30),

                // Nút Đăng nhập
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}