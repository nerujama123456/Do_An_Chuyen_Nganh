// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> registerNewStaff(String email, String password, Map<String, dynamic> staffInfo) async {
    // Không cần lưu currentSession nữa

    try {
      // 1. Tạo tài khoản Auth trên Supabase
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final String? authId = authResponse.user?.id;

      if (authId == null) {
        // Xử lý lỗi nếu không tạo được Auth ID
        return 'Lỗi: Không thể tạo tài khoản xác thực.';
      }

      // 2. Tạo hồ sơ chi tiết trong bảng public.users
      final Map<String, dynamic> profileData = {
        'auth_id': authId,
        'hovaten': staffInfo['hovaten'],
        'gioitinh': staffInfo['gioitinh'],
        'sodienthoai': staffInfo['sodienthoai'],
        'ngaysinh': staffInfo['ngaysinh'],
        'diachi': staffInfo['diachi'],
        'role_id': staffInfo['role_id'],
      };

      await _supabase.from('users').insert(profileData);

      // !!! BƯỚC 3: KHÔNG CẦN KHÔI PHỤC PHIÊN ADMIN
      // Hàm này chỉ trả về null nếu thành công. Việc đăng xuất sẽ được gọi từ form.

      return null; // Thành công

    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Lỗi khi lưu hồ sơ: ${e.toString()}';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final authId = response.user!.id;
        await _loadAndCacheUserPermissions(authId);
        return null;
      }
      return 'Lỗi đăng nhập không xác định.';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Lỗi không xác định: $e';
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_permissions');
    await _supabase.auth.signOut();
  }

  Future<void> _loadAndCacheUserPermissions(String authId) async {
    final prefs = await SharedPreferences.getInstance();
    // Tạm thời bỏ qua logic chi tiết này để tập trung vào vai trò
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return null;

    try {
      final userResponse = await _supabase
          .from('users')
          .select('auth_id, hovaten, role_id')
          .eq('auth_id', userId)
          .single();

      if (userResponse == null || userResponse.isEmpty) {
        return {'role_name': 'Khách'};
      }

      final roleResponse = await _supabase.from('roles').select('tenvaitro').eq('id', userResponse['role_id']).single();

      return {
        ...userResponse,
        'role_name': roleResponse['tenvaitro'],
      };
    } catch (e) {
      print('Error fetching user info/role: $e');
      return {'role_name': 'Khách'};
    }
  }

  Future<String> getUserRoleName() async {
    final userInfo = await getCurrentUserInfo();
    return userInfo?['role_name'] as String? ?? 'Khách';
  }


}