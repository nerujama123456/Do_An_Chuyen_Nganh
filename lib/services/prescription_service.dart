// lib/services/prescription_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prescription.dart';
import '../models/prescription_detail.dart';

class PrescriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Prescription>> fetchPrescriptions() async {
    try {
      final List<dynamic> response = await _supabase
          .from('prescriptions')
          .select('''
                  *,
                  patients(hovaten),
                  users(hovaten)
              ''')
          .order('ma', ascending: true);

      return response.map((map) {
        final patientName = (map['patients'] as Map?)?['hovaten'] ?? map['tenbenhnhan'] ?? 'N/A';
        final doctorName = (map['users'] as Map?)?['hovaten'] ?? map['bacsi'] ?? 'N/A';

        return Prescription.fromJson({
          ...map,
          'tenbenhnhan': patientName,
          'bacsi': doctorName,
          'tongtien': map['tongtien'],
          'trangthai': map['trangthai'],
        });
      }).toList();
    } catch (error) {
      throw Exception('Lỗi tải đơn thuốc từ Supabase: $error');
    }
  }
  Future<bool> completePrescriptionPayment(String prescriptionId) async {
    try {
      final updateData = {
        'trangthai': 'Hoàn thành', // Trạng thái mới
      };

      final response = await _supabase
          .from('prescriptions')
          .update(updateData)
          .eq('id', int.parse(prescriptionId))
          .eq('trangthai', 'Chưa mua'); // Chỉ cập nhật nếu trạng thái cũ là 'Chưa mua'

      // Postgrest update thường trả về List<Map> của các hàng đã thay đổi.
      // Nếu response không phải là null và có ít nhất 1 hàng được cập nhật, thì thành công.
      return response != null && response.isNotEmpty;

    } on PostgrestException catch (e) {
      print('Lỗi hoàn thành thanh toán đơn thuốc: ${e.message}');
      return false;
    } catch (e) {
      return false;
    }
  }
  Future<List<PrescriptionDetail>> getPrescriptionDetails(String prescriptionId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('prescription_details')
          .select('*')
          .eq('prescription_id', int.parse(prescriptionId))
          .order('id', ascending: true);

      return response.map((map) => PrescriptionDetail.fromJson(map)).toList();
    } catch (error) {
      throw Exception('Lỗi tải chi tiết đơn thuốc: $error');
    }
  }
  /// Lấy thông tin Header đơn thuốc (Tái sử dụng fetch, nhưng dùng single)
  Future<Map<String, dynamic>> getPrescriptionHeader(String prescriptionId) async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('''
                  *,
                  patients(hovaten),
                  users(hovaten)
              ''')
          .eq('id', int.parse(prescriptionId))
          .single();

      // Tái cấu trúc Map
      final patientName = (response['patients'] as Map?)?['hovaten'] ?? response['tenbenhnhan'] ?? 'N/A';
      final doctorName = (response['users'] as Map?)?['hovaten'] ?? response['bacsi'] ?? 'N/A';

      return {
        ...response,
        'tenbenhnhan': patientName,
        'bacsi': doctorName,
      };
    } catch (error) {
      throw Exception('Lỗi tải header đơn thuốc: $error');
    }
  }
  /// Cập nhật Đơn thuốc và Chi tiết
  Future<bool> updatePrescription(String prescriptionId, Map<String, dynamic> headerData, List<Map<String, dynamic>> detailData) async {
    try {
      final pId = int.parse(prescriptionId);

      // 1. Cập nhật Header
      await _supabase
          .from('prescriptions')
          .update(headerData)
          .eq('id', pId);

      // 2. Xóa tất cả chi tiết cũ
      await _supabase
          .from('prescription_details')
          .delete()
          .eq('prescription_id', pId);

      // 3. Thêm chi tiết mới (ĐÃ SỬA LỖI ÉP KIỂU NULL)
      final detailsToInsert = detailData.map((detail) => {
        // Sử dụng ?? 0 (hoặc kiểm tra null) cho các trường số
        'prescription_id': pId,
        'medicine_id': detail['medicine_id'] as int,
        'tenthuoc': detail['tenthuoc'] as String?,
        'donvitinh': detail['donvitinh'] as String?,
        // !!! ÉP KIỂU AN TOÀN: Dùng (as int? ?? 0)
        'soluong': detail['soluong'] as int? ?? 0,
        'cachdung': detail['cachdung'] as String?,
        'giavnd': detail['giavn'] as int? ?? 0,
        'tongtien': detail['tongtien'] as int? ?? 0,
      }).toList();

      if (detailsToInsert.isNotEmpty) {
        await _supabase.from('prescription_details').insert(detailsToInsert);
      }

      return true;
    } on PostgrestException catch (e) {
      throw Exception('Lỗi cập nhật đơn thuốc: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi cập nhật đơn thuốc: $e');
    }
  }
  // Hàm Delete: Xóa Đơn thuốc và Chi tiết liên quan
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      final pId = int.parse(prescriptionId);

      // Xóa Chi tiết đơn thuốc trước (Nếu không dùng CASCADE)
      // await _supabase.from('prescription_details').delete().eq('prescription_id', pId);

      // Xóa Đơn thuốc chính (Giả định bảng details có ON DELETE CASCADE)
      await _supabase
          .from('prescriptions')
          .delete()
          .eq('id', pId);

      return true;
    } on PostgrestException catch (e) {
      print('Lỗi xóa đơn thuốc: ${e.message}');
      // Ném lỗi để UI hiển thị thông báo thất bại
      throw Exception('Xóa đơn thuốc thất bại: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi xóa đơn thuốc: $e');
    }
  }
  Future<bool> createPrescription(Map<String, dynamic> headerData, List<Map<String, dynamic>> detailData) async {
    try {
      // 1. Thêm Đơn thuốc chính
      final prescriptionResponse = await _supabase
          .from('prescriptions')
          .insert([headerData])
          .select('id')
          .single();

      final prescriptionId = prescriptionResponse['id'];

      // 2. Thêm Chi tiết đơn thuốc (ÁNH XẠ CHỮ THƯỜNG)
      final detailsToInsert = detailData.map((detail) => {
        'prescription_id': prescriptionId,
        'medicine_id': detail['medicine_id'] as int,
        'tenthuoc': detail['tenthuoc'] as String?,       // SỬA: tenThuoc -> tenthuoc
        'donvitinh': detail['donvitinh'] as String?,     // SỬA: donViTinh -> donvitinh
        'soluong': detail['soluong'] as int,             // SỬA: soLuong -> soluong
        'cachdung': detail['cachdung'] as String?,       // SỬA: cachDung -> cachdung
        'giavnd': detail['giavnd'] as int,               // SỬA: giaVND -> giavnd
        'tongtien': detail['tongtien'] as int,           // SỬA: tongTien -> tongtien
      }).toList();

      await _supabase.from('prescription_details').insert(detailsToInsert);
      return true;
    } on PostgrestException catch (e) {
      print('Lỗi Supabase khi tạo đơn thuốc: ${e.message}');
      return false;
    } catch (e) {
      print('Lỗi không xác định khi tạo đơn thuốc: $e');
      return false;
    }
  }
}