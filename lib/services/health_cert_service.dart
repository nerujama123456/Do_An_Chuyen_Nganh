// lib/services/health_cert_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_certification.dart';
import '../models/prescription_detail.dart';

class HealthCertService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<HealthCertification>> fetchHealthCertifications() async {
    try {
      final List<dynamic> response = await _supabase
          .from('health_certifications')
          .select('''
                  *,
                  patients(hovaten),           
                  consulting_rooms(tenphongkham), 
                  users(hovaten)             
              ''')
          .order('id', ascending: true);

      return response.map((map) {
        final patientName = (map['patients'] as Map?)?['hovaten'] ?? map['tenbenhnhan'] ?? 'N/A';
        final roomName = (map['consulting_rooms'] as Map?)?['tenphongkham'] ?? 'N/A';
        final doctorName = (map['users'] as Map?)?['hovaten'] ?? 'N/A';

        return HealthCertification.fromJson({
          ...map,
          'tenbenhnhan': patientName,
          'phongkham': roomName,
          'bacsi': doctorName,
          'ketluan': map['ketluan'],
          'huongdandieutri': map['huongdandieutri'],
          'denghikhamlamsang': map['denghikhamlamsang'],
          'trangthai': map['trangthai'],
          'thanhtoan': map['thanhtoan'],
          'gia': map['gia'],
        });
      }).toList();
    } catch (error) {
      throw Exception('Lỗi tải giấy khám bệnh từ Supabase: $error');
    }
  }
  /// Cập nhật trạng thái Thanh toán Giấy Khám Bệnh
  Future<bool> markCertAsPaid(String certId) async {
    try {
      final updateData = {'thanhtoan': 'Đã thanh toán'};
      await _supabase
          .from('health_certifications')
          .update(updateData)
          .eq('id', int.parse(certId))
          .eq('thanhtoan', 'Chưa thanh toán');

      return true;
    } on PostgrestException catch (e) {
      print('Lỗi xác nhận thanh toán giấy khám bệnh: ${e.message}');
      return false;
    }
  }
  Future<HealthCertification> getHealthCertification(String id) async {
    final response = await _supabase
        .from('health_certifications')
        .select('''
              *,
              patients(hovaten),
              consulting_rooms(tenphongkham),
              users(hovaten)
          ''')
        .eq('id', int.parse(id))
        .single();

    final patientName = (response['patients'] as Map?)?['hovaten'] ?? response['tenbenhnhan'] ?? 'N/A';
    final roomName = (response['consulting_rooms'] as Map?)?['tenphongkham'] ?? 'N/A';
    final doctorName = (response['users'] as Map?)?['hovaten'] ?? 'N/A';

    return HealthCertification.fromJson({
      ...response,
      'tenbenhnhan': patientName,
      'phongkham': roomName,
      'bacsi': doctorName,
      'ketluan': response['ketluan'],
      'huongdandieutri': response['huongdandieutri'],
      'denghikhamlamsang': response['denghikhamlamsang'],
    });
  }

  Future<bool> createHealthCertification(Map<String, dynamic> data) async {
    final Map<String, dynamic> dataToSend = {
      'ma': data['ma'],
      'title': data['title'],
      'patient_id': data['patient_id'],
      'tenbenhnhan': data['tenbenhnhan'],
      'phongkham_id': data['phongkham_id'], // SỬA: Bị lỗi đánh máy ở đây
      'user_id': data['user_id'],
      'ngay': data['ngay'],
      'gia': data['gia'],
      'trangthai': data['trangthai'],
      'thanhtoan': data['thanhtoan'],
    };

    try {
      await _supabase.from('health_certifications').insert(dataToSend);
      return true;
    } on PostgrestException catch (e) {
      print('Lỗi tạo giấy khám bệnh: ${e.message}');
      return false;
    }
  }

  Future<bool> updateHealthCertConclusion(String id, Map<String, dynamic> data) async {
    final Map<String, dynamic> updateData = {
      'ketluan': data['ketluan'],
      'huongdandieutri': data['huongdandieutri'],
      'denghikhamlamsang': data['denghikhamlamsang'],
      'trangthai': data['trangthai'],
    };

    try {
      await _supabase.from('health_certifications').update(updateData).eq('id', int.parse(id));
      return true;
    } on PostgrestException catch (e) {
      print('Lỗi cập nhật kết luận: ${e.message}');
      return false;
    }
  }

  Future<bool> markHealthCertAsExamined(String id) async {
    final data = {
      'trangthai': 'Đã khám',
      'ketluan': 'Đã khám và chờ kết luận chi tiết',
      'huongdandieutri': 'Liên hệ bác sĩ sau',
    };
    return updateHealthCertConclusion(id, data);
  }
  // lib/services/health_cert_service.dart (Hoặc supabase_service.dart)
  Future<List<PrescriptionDetail>> getPrescriptionDetailsByPrescriptionId(int prescriptionId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('prescription_details')
          .select('*')
          .eq('prescription_id', prescriptionId)
          .order('id', ascending: true);

      return response.map((map) => PrescriptionDetail.fromJson(map)).toList();
    } catch (error) {
      print('Lỗi tải chi tiết đơn thuốc: $error');
      return [];
    }
  }
  Future<Map<String, dynamic>?> getPrescriptionHeaderByPrescriptionId(int prescriptionId) async {
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('''
                  *,
                  patients(hovaten),
                  users(hovaten)
              ''')
          .eq('id', prescriptionId)
          .single();

      if (response == null) return null;

      // Tái cấu trúc Map
      final patientName = (response['patients'] as Map?)?['hovaten'] ?? response['tenbenhnhan'] ?? 'N/A';
      final doctorName = (response['users'] as Map?)?['hovaten'] ?? response['bacsi'] ?? 'N/A';

      return {
        ...response,
        'tenbenhnhan': patientName,
        'bacsi': doctorName,
      };
    } catch (error) {
      print('Lỗi tải header đơn thuốc: $error');
      return null;
    }
  }
  Future<bool> deleteHealthCertification(String id) async {
    try {
      // Sử dụng execute() để kiểm tra rõ ràng hơn nếu cần, hoặc dựa vào PostgrestException.
      await _supabase
          .from('health_certifications')
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