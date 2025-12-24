// lib/services/service_voucher_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_voucher.dart';

class ServiceVoucherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cấu trúc SELECT sử dụng JOIN cho hiển thị
  Future<List<ServiceVoucher>> fetchServiceVouchers() async {
    try {
      final List<dynamic> response = await _supabase
          .from('service_vouchers')
          .select('''
              *,
              patients(hovaten),
              medical_services(tendichvu),
              users(hovaten)
          ''')
          .order('id', ascending: true);

      return response.map((map) {
        final patientName = (map['patients'] as Map?)?['hovaten'] ?? map['tenbenhnhan'] ?? 'N/A';
        final dichVu = (map['medical_services'] as Map?)?['tendichvu'] ?? 'N/A';
        final bacSi = (map['users'] as Map?)?['hovaten'] ?? 'N/A';

        return ServiceVoucher.fromJson({
          ...map,
          'tenbenhnhan': patientName,
          'dichvukham': dichVu,
          'bacsi': bacSi,
        });
      }).toList();
    } catch (error) {
      throw Exception('Lỗi tải phiếu dịch vụ: $error');
    }
  }
  /// Cập nhật trạng thái Thanh toán Phiếu Dịch Vụ
  Future<bool> markVoucherAsPaid(String voucherId) async {
    try {
      final updateData = {'thanhtoan': 'Đã thanh toán'};
      await _supabase
          .from('service_vouchers')
          .update(updateData)
          .eq('id', int.parse(voucherId))
          .eq('thanhtoan', 'Chưa thanh toán');

      return true;
    } on PostgrestException catch (e) {
      print('Lỗi xác nhận thanh toán phiếu dịch vụ: ${e.message}');
      return false;
    }
  }
  /// Chức năng 1: Cập nhật trạng thái Khám xong (Hoàn thành)
  Future<bool> markVoucherAsCompleted(String voucherId) async {
    try {
      final updateData = {'trangthai': 'Đã khám xong'};

      await _supabase
          .from('service_vouchers')
          .update(updateData)
          .eq('id', int.parse(voucherId))
          .eq('thanhtoan', 'Đã thanh toán'); // Đảm bảo chỉ hoàn thành khi đã thanh toán

      return true;
    } on PostgrestException catch (e) {
      throw Exception('Lỗi hoàn thành phiếu dịch vụ: ${e.message}');
    }
  }

  /// Chức năng 2: Cập nhật thông tin Phiếu Dịch Vụ (cho Edit Screen)
  Future<bool> updateServiceVoucher(String voucherId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('service_vouchers')
          .update(data)
          .eq('id', int.parse(voucherId));
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật phiếu dịch vụ thất bại: ${e.message}');
    }
  }
  // HÀM MỚI: Lấy chi tiết Phiếu Dịch Vụ
  Future<ServiceVoucher> getServiceVoucherDetail(String voucherId) async {
    try {
      final response = await _supabase
          .from('service_vouchers')
          .select('''
              *,
              patients(hovaten),
              medical_services(tendichvu),
              users(hovaten)
          ''')
          .eq('id', int.parse(voucherId))
          .single();

      final patientName = (response['patients'] as Map?)?['hovaten'] ?? response['tenbenhnhan'] ?? 'N/A';
      final dichVu = (response['medical_services'] as Map?)?['tendichvu'] ?? 'N/A';
      final bacSi = (response['users'] as Map?)?['hovaten'] ?? 'N/A';

      return ServiceVoucher.fromJson({
        ...response,
        'tenbenhnhan': patientName,
        'dichvukham': dichVu,
        'bacsi': bacSi,
      });
    } catch (error) {
      throw Exception('Lỗi tải chi tiết phiếu dịch vụ: $error');
    }
  }

  // Thêm mới Phiếu Dịch Vụ
  Future<bool> createServiceVoucher(Map<String, dynamic> data) async {
    try {
      await _supabase.from('service_vouchers').insert(data);
      return true;
    } on PostgrestException catch (e) {
      print('Lỗi tạo phiếu dịch vụ: ${e.message}');
      return false;
    }
  }

  Future<bool> deleteServiceVoucher(String id) async {
    try {
      // Sử dụng execute() để kiểm tra rõ ràng hơn nếu cần, hoặc dựa vào PostgrestException.
      await _supabase
          .from('service_vouchers')
          .delete()
          .eq('id', int.parse(id));

      return true; // Giả định thành công nếu không có exception
    } on PostgrestException catch (e) {
      print('DELETE FAILED DUE TO RLS/DB: ${e.message}');
      return false; // Trả về false nếu Supabase ném lỗi
    } catch (e) {
      return false;
    }
  }
}