// lib/services/data_service.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import '../models/consulting_room.dart';
import '../models/medical_service.dart';
import '../models/medicine.dart';
import '../models/medicine_type.dart';
import '../models/patient.dart';
import '../models/user_info.dart'; // Cần Model chi tiết User (sẽ tạo)
class DataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchPatients() async {
    final response = await _supabase.from('patients').select('id,ma, hovaten,gioitinh,sodienthoai, ngaysinh,diachi').order('id', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchConsultingRooms() async {
    final response = await _supabase.from('consulting_rooms').select('id,ma, tenphongkham').order('id', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchMedicines() async {
    final response = await _supabase
        .from('medicines')
        .select('id, ma, tenthuoc, giavnd, donvitinh') // Đã sửa tên cột
        .order('id', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }
  Future<ConsultingRoom> getConsultingRoomDetail(int roomId) async {
    try {
      final response = await _supabase
          .from('consulting_rooms')
          .select('*')
          .eq('id', roomId)
          .single();

      return ConsultingRoom.fromJson(response);
    } catch (error) {
      throw Exception('Lỗi tải chi tiết phòng khám: $error');
    }
  }
  /// Cập nhật hồ sơ Bác sĩ (KHÔNG CHẠM VÀO role_id)
  Future<bool> updateDoctorProfile(String authId, Map<String, dynamic> data) async {
    try {
      // Chỉ gửi các trường profile (không gửi auth_id, role_id)
      await _supabase
          .from('users')
          .update(data)
          .eq('auth_id', authId);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật hồ sơ bác sĩ thất bại: ${e.message}');
    }
  }
  /// Cập nhật thông tin Phòng Khám
  Future<bool> updateConsultingRoom(int roomId, String tenphongkham) async {
    try {
      final data = {
        'tenphongkham': tenphongkham,
      };
      await _supabase
          .from('consulting_rooms')
          .update(data)
          .eq('id', roomId);
      return true;
    } on PostgrestException catch (e) {
      // Lỗi do trùng mã/tên
      throw Exception('Cập nhật thất bại. Lỗi: ${e.message}');
    } catch (e) {
      return false;
    }
  }



  // !!! HÀM MỚI: Tải danh sách Nhân viên (users)
  Future<List<UserInfo>> fetchStaffList() async {
    // JOIN trực tiếp với roles(tenvaitro) qua FK role_id
    try {
      final response = await _supabase
          .from('users')
          .select('*, roles(tenvaitro)')
          .order('hovaten', ascending: true);

      return response.map((map) {
        final roleName = (map['roles'] as Map?)?['tenvaitro'] ?? 'N/A';
        return UserInfo.fromJson({...map, 'role_name': roleName});
      }).toList();
    } catch (e) {
      throw Exception('Lỗi tải danh sách nhân sự: ${e.toString()}');
    }
  }
  Future<List<Map<String, dynamic>>> fetchRoles() async {
    try {
      final response = await _supabase.from('roles').select('id, tenvaitro').order('id', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Lỗi tải danh sách vai trò: ${e.toString()}');
    }
  }
  /// Tải danh sách TẤT CẢ Lịch Hẹn (bao gồm cả quá khứ và tương lai)
  Future<List<Appointment>> fetchAllAppointments() async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('''
              *,
              users(hovaten) -- JOIN để lấy tên Bác sĩ
          ''')
          .order('ngaydathen', ascending: false) // Sắp xếp từ mới nhất
          .order('giodathen', ascending: false);

      return response.map((map) {
        final doctorName = (map['users'] as Map?)?['hovaten'] ?? 'N/A';
        return Appointment.fromJson({...map, 'bacsi': doctorName});
      }).toList();
    } catch (error) {
      throw Exception('Lỗi tải danh sách tất cả lịch hẹn: $error');
    }
  }

  /// Cập nhật vai trò của một người dùng (User Role)
  Future<bool> updateUserRole(String authId, int roleId) async {
    try {
      final data = {'role_id': roleId};
      await _supabase
          .from('users')
          .update(data)
          .eq('auth_id', authId);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật vai trò thất bại: ${e.message}');
    }
  }

  /// Tải danh sách Lịch Hẹn trong ngày hôm nay (ĐÃ SỬA JOIN)
  Future<List<Appointment>> fetchTodayAppointments() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final response = await _supabase
          .from('appointments')
          .select('''
              *,
              users!appointments_bacsi_id_fkey(hovaten) -- JOIN LẤY TÊN BÁC SĨ
          ''')
          .eq('ngaydathen', today)
          .order('giodathen', ascending: true);

      return response.map((map) {
        // Lấy tên bác sĩ từ kết quả JOIN
        final doctorName = (map['users'] as Map?)?['hovaten'] ?? 'N/A';

        return Appointment.fromJson({
          ...map,
          // Gán tên bác sĩ vào trường 'bacsi' của Model
          'bacsi': doctorName
        });
      }).toList();
    } catch (error) {
      throw Exception('Lỗi tải danh sách lịch hẹn trong ngày: $error');
    }
  }


  Future<bool> confirmAppointment(String appointmentId) async {
    try {
      final updateData = {'trangthai': 'Đã xác nhận khám'};

      await _supabase
          .from('appointments')
          .update(updateData)
          .eq('id', int.parse(appointmentId))
          .eq('trangthai', 'Chờ xác nhận');

      return true;
    } on PostgrestException catch (e) {
      print('Lỗi xác nhận lịch hẹn: ${e.message}');
      return false;
    } catch (e) {
      return false;
    }
  }
  Future<Appointment> getAppointmentDetail(String appointmentId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('''
              *,
              patients(hovaten),
              users(hovaten)
          ''')
          .eq('id', int.parse(appointmentId))
          .single();

      final doctorName = (response['users'] as Map?)?['hovaten'] ?? 'N/A';

      return Appointment.fromJson({
        ...response,
        'bacsi': doctorName
      });
    } catch (error) {
      throw Exception('Lỗi tải chi tiết lịch hẹn: $error');
    }
  }

  // !!! HÀM XÓA LỊCH HẸN
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .delete()
          .eq('id', int.parse(appointmentId));

      return true;
    } on PostgrestException catch (e) {
      throw Exception('Xóa lịch hẹn thất bại: ${e.message}');
    }
  }

  // !!! HÀM CẬP NHẬT LỊCH HẸN (Sẽ sử dụng lại trong Edit Screen)
  Future<bool> updateAppointment(String appointmentId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('appointments')
          .update(data)
          .eq('id', int.parse(appointmentId));
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật lịch hẹn thất bại: ${e.message}');
    }
  }
  /// Tìm kiếm bệnh nhân theo Số điện thoại
  Future<List<Map<String, dynamic>>> searchPatientByPhone(String phone) async {
    // Đảm bảo SĐT không bị định dạng (dấu cách, gạch ngang)
    final cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');
    try {
      final response = await _supabase
          .from('patients')
          .select('id, hovaten, gioitinh, ngaysinh, diachi, sodienthoai')
          .eq('sodienthoai', cleanedPhone); // Tìm chính xác theo SĐT đã làm sạch

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Log lỗi Supabase nếu có
      print('Supabase Error searching phone: $e');
      return [];
    }
  }

  /// Thêm mới Lịch Hẹn (ĐÃ BỎ CHUYENKHOA)
  Future<bool> createAppointment(Map<String, dynamic> data) async {
    try {
      // Data đã được chuẩn bị sẵn trong form (không có chuyen_khoa)
      final dataToSend = {
        ...data,
        'ma': 'LH${DateTime.now().millisecondsSinceEpoch}',
      };
      // Giả sử các trường chỉ số sinh tồn đã được chuyển về kiểu số an toàn

      await _supabase.from('appointments').insert(dataToSend);
      return true;
    } on PostgrestException catch (e) {
      // Lỗi thường do thiếu trường NOT NULL hoặc lỗi kiểu dữ liệu
      throw Exception('Tạo lịch hẹn thất bại: ${e.message}');
    }
  }

  /// Lấy chi tiết một Dịch vụ Khám
  Future<MedicalService> getMedicalServiceDetail(int serviceId) async {
    try {
      final response = await _supabase
          .from('medical_services')
          .select('*')
          .eq('id', serviceId)
          .single();

      return MedicalService.fromJson(response);
    } catch (error) {
      throw Exception('Lỗi tải chi tiết dịch vụ: $error');
    }
  }

  /// Thêm mới Dịch vụ Khám
  Future<bool> createMedicalService(String ma, String tendichvu, int giavnd) async {
    try {
      final data = {
        'ma': ma,
        'tendichvu': tendichvu,
        'giavnd': giavnd,
      };
      await _supabase.from('medical_services').insert(data);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Tạo dịch vụ thất bại: ${e.message}');
    }
  }

  /// Cập nhật Dịch vụ Khám
  Future<bool> updateMedicalService(int serviceId, String tendichvu, int giavnd) async {
    try {
      final data = {
        'tendichvu': tendichvu,
        'giavnd': giavnd,
      };
      await _supabase
          .from('medical_services')
          .update(data)
          .eq('id', serviceId);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật thất bại: ${e.message}');
    }
  }
  Future<bool> createConsultingRoom(String ma, String tenphongkham) async {
    try {
      final data = {
        'ma': ma,
        'tenphongkham': tenphongkham, // Tên cột chữ thường
      };
      await _supabase.from('consulting_rooms').insert(data);
      return true;
    } on PostgrestException catch (e) {
      print('Lỗi tạo phòng khám: ${e.message}');
      // Trả về false và ném lỗi để Form hiển thị thông báo
      throw Exception('Mã phòng khám đã tồn tại hoặc lỗi server.');
    } catch (e) {
      return false;
    }
  }
  /// Tải danh sách Loại Thuốc
  Future<List<Map<String, dynamic>>> fetchMedicineTypes() async {
    final response = await _supabase.from('medicine_types').select('id, ma, tenloaithuoc').order('tenloaithuoc', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Lấy chi tiết một Loại Thuốc
  Future<MedicineType> getMedicineTypeDetail(int typeId) async {
    try {
      final response = await _supabase
          .from('medicine_types')
          .select('*')
          .eq('id', typeId)
          .single();

      return MedicineType.fromJson(response);
    } catch (error) {
      throw Exception('Lỗi tải chi tiết loại thuốc: $error');
    }
  }
  /// Lấy chi tiết một Bệnh nhân
  Future<Patient> getPatientDetail(int patientId) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('*')
          .eq('id', patientId)
          .single();

      return Patient.fromJson(response);
    } catch (error) {
      throw Exception('Lỗi tải chi tiết bệnh nhân: $error');
    }
  }

  /// Thêm mới Bệnh nhân
  Future<bool> createPatient(Map<String, dynamic> data) async {
    try {
      // Mã bệnh nhân sẽ được tạo trong Form
      await _supabase.from('patients').insert(data);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Tạo bệnh nhân thất bại: ${e.message}');
    }
  }

  /// Cập nhật Bệnh nhân
  Future<bool> updatePatient(int patientId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('patients')
          .update(data)
          .eq('id', patientId);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật thất bại: ${e.message}');
    }
  }
  // !!! HÀM MỚI: Tải danh sách Thuốc
  Future<List<Medicine>> fetchMedicinesList() async {
    // JOIN với medicine_types để lấy tên loại thuốc
    final response = await _supabase
        .from('medicines')
        .select('*, medicine_types(tenloaithuoc)')
        .order('tenthuoc', ascending: true);

    return response.map((map) {
      final typeName = (map['medicine_types'] as Map?)?['tenloaithuoc'] ?? 'N/A';
      return Medicine.fromJson({...map, 'tenloaithuoc': typeName});
    }).toList();
  }

  /// Thêm mới Thuốc
  Future<bool> createMedicine(String ma, String tenthuoc, int loaithuocId, int giavnd, String donvitinh, String mota) async {
    try {
      final data = {
        'ma': ma,
        'tenthuoc': tenthuoc,
        'loaithuoc_id': loaithuocId,
        'giavnd': giavnd,
        'donvitinh': donvitinh,
        'mota': mota,
      };
      await _supabase.from('medicines').insert(data);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Tạo thuốc thất bại: ${e.message}');
    }
  }
  /// Lấy chi tiết hồ sơ User (Doctor/Staff) theo Auth ID
  Future<Map<String, dynamic>> getUserProfile(String authId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, roles(tenvaitro)') // JOIN để lấy tên vai trò
          .eq('auth_id', authId)
          .single();

      final roleName = (response['roles'] as Map?)?['tenvaitro'] ?? 'N/A';

      return {
        ...response,
        'role_name': roleName,
      };
    } catch (error) {
      throw Exception('Lỗi tải hồ sơ người dùng: $error');
    }
  }
  /// Thêm mới Bệnh nhân VÀ TRẢ VỀ ID MỚI TẠO
  Future<int> createPatientAndGetId(Map<String, dynamic> data) async {
    try {
      // Supabase insert với .select('id').single() sẽ trả về Map của hàng vừa tạo
      final response = await _supabase
          .from('patients')
          .insert(data)
          .select('id')
          .single();

      return response['id'] as int; // Trả về ID mới
    } on PostgrestException catch (e) {
      throw Exception('Tạo bệnh nhân thất bại: ${e.message}');
    }
  }
  /// Lấy chi tiết một Thuốc
  Future<Medicine> getMedicineDetail(int medicineId) async {
    final response = await _supabase
        .from('medicines')
        .select('*, medicine_types(tenloaithuoc)')
        .eq('id', medicineId)
        .single();

    final typeName = (response['medicine_types'] as Map?)?['tenloaithuoc'] ?? 'N/A';
    return Medicine.fromJson({...response, 'tenloaithuoc': typeName});
  }

  /// Cập nhật Thuốc
  Future<bool> updateMedicine(int id, String tenthuoc, int loaithuocId, int giavnd, String donvitinh, String mota) async {
    try {
      final data = {
        'tenthuoc': tenthuoc,
        'loaithuoc_id': loaithuocId,
        'giavnd': giavnd,
        'donvitinh': donvitinh,
        'mota': mota,
      };
      await _supabase.from('medicines').update(data).eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật thất bại: ${e.message}');
    }
  }
  /// Thêm mới Loại Thuốc
  Future<bool> createMedicineType(String ma, String tenloaithuoc) async {
    try {
      final data = {
        'ma': ma,
        'tenloaithuoc': tenloaithuoc,
      };
      await _supabase.from('medicine_types').insert(data);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Tạo loại thuốc thất bại: ${e.message}');
    }
  }

  /// Cập nhật Loại Thuốc
  Future<bool> updateMedicineType(int typeId, String tenloaithuoc) async {
    try {
      final data = {
        'tenloaithuoc': tenloaithuoc,
      };
      await _supabase
          .from('medicine_types')
          .update(data)
          .eq('id', typeId);
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Cập nhật thất bại: ${e.message}');
    }
  }
  Future<List<Map<String, dynamic>>> fetchMedicalServices() async {
    try {
      final response = await _supabase.from('medical_services').select('id,ma, tendichvu, giavnd').order('id', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Lỗi tải danh sách dịch vụ: $e');
      return [];
    }
  }
  Future<bool> deleteCatalogItem(String tableName, int id) async {
    try {
      await _supabase
          .from(tableName)
          .delete()
          .eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      print('Lỗi xóa danh mục $tableName: ${e.message}');
      return false;
    }
  }
  /// Xóa hồ sơ Bệnh nhân và tất cả dữ liệu giao dịch liên quan
  Future<bool> deletePatientAndRecords(int patientId) async {
    try {
      // --- 1. XÓA CÁC BẢNG GIAO DỊCH PHỤ THUỘC (ORDER MATTERS!) ---

      // LƯU Ý: Nếu đã có ON DELETE CASCADE trên prescriptions (cho details),
      // bạn chỉ cần xóa bảng chính prescriptions. Nếu không, phải xóa details trước.

      // 1.1. Xóa Lịch hẹn (appointments)
      await _supabase.from('appointments').delete().eq('patient_id', patientId);

      // 1.2. Xóa Phiếu Dịch Vụ (service_vouchers)
      await _supabase.from('service_vouchers').delete().eq('patient_id', patientId);

      // 1.3. Xóa Giấy Khám Bệnh (health_certifications)
      // (Điều này có thể xóa cả Đơn thuốc nếu health_certifications có FK đến prescriptions)
      await _supabase.from('health_certifications').delete().eq('patient_id', patientId);



      // 1.5. Xóa Đơn thuốc còn sót (Nếu có đơn thuốc không liên kết với health_cert)
      // LƯU Ý: Cần xử lý chi tiết đơn thuốc nếu prescriptions không có CASCADE cho details
      await _supabase.from('prescriptions').delete().eq('patient_id', patientId);

      // --- 2. XÓA HỒ SƠ BỆNH NHÂN CHÍNH ---
      await _supabase.from('patients').delete().eq('id', patientId);

      return true;
    } on PostgrestException catch (e) {
      // Lỗi thường do FKs còn sót lại hoặc lỗi database
      throw Exception('Xóa thất bại: ${e.message}. Kiểm tra lại các ràng buộc FK.');
    } catch (e) {
      throw Exception('Lỗi không xác định khi xóa bệnh nhân: $e');
    }
  }
  Future<bool> deleteUser(String authId) async {
    try {
      final  _adminApi = _supabase.auth.admin;

      // 1. XÓA CÁC BẢNG PHỤ THUỘC TRỰC TIẾP TỪ USER_ID (ĐỂ TRÁNH LỖI FK)

      // Xóa Lịch hẹn (appointments)
      await _supabase.from('appointments').delete().eq('bacsi_id', authId);

      // Xóa Phiếu Dịch vụ (service_vouchers)
      await _supabase.from('service_vouchers').delete().eq('user_id', authId);

      // Xóa Đơn thuốc (prescriptions)
      // *LƯU Ý: Nếu đơn thuốc có chi tiết, chi tiết phải được xóa trước, nhưng
      // nếu bạn đã dùng CASCADE trong DB, chỉ cần xóa bảng chính.*
      // Tạm thời chỉ xóa header, dựa vào FK CASCADE trong DB để xóa detail
      await _supabase.from('prescriptions').delete().eq('user_id', authId);

      // Xóa Giấy Khám Bệnh (health_certifications)
      await _supabase.from('health_certifications').delete().eq('user_id', authId);

      // 2. XÓA HỒ SƠ KHỎI BẢNG public.users
      await _supabase.from('users').delete().eq('auth_id', authId);

      // 3. XÓA TÀI KHOẢN KHỎI SUPABASE AUTH
      await _adminApi.deleteUser(authId);

      return true;
    } on PostgrestException catch (e) {
      throw Exception('Xóa hồ sơ thất bại: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('Xóa tài khoản Auth thất bại: ${e.message}');
    }
  }
  /// Tải dữ liệu tổng quan cho Dashboard
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // --- 1. TÍNH DOANH THU THỰC TẾ ---

      // 1.1. Doanh thu Giấy Khám Bệnh (thanhtoan = Đã thanh toán)
      final certRevenueResult = await _supabase
          .from('health_certifications')
          .select('gia')
          .eq('thanhtoan', 'Đã thanh toán');
      final certRevenue = (certRevenueResult as List<dynamic>).fold(0, (sum, row) => sum + (row['gia'] as int? ?? 0));

      // 1.2. Doanh thu Phiếu Dịch Vụ (thanhtoan = Đã thanh toán)
      final voucherRevenueResult = await _supabase
          .from('service_vouchers')
          .select('tongtien')
          .eq('thanhtoan', 'Đã thanh toán');
      final voucherRevenue = (voucherRevenueResult as List<dynamic>).fold(0, (sum, row) => sum + (row['tongtien'] as int? ?? 0));

      // 1.3. Doanh thu Đơn Thuốc (trangthai = Hoàn thành)
      final prescriptionRevenueResult = await _supabase
          .from('prescriptions')
          .select('tongtien')
          .eq('trangthai', 'Hoàn thành');
      final prescriptionRevenue = (prescriptionRevenueResult as List<dynamic>).fold(0, (sum, row) => sum + (row['tongtien'] as int? ?? 0));

      final totalRevenue = certRevenue + voucherRevenue + prescriptionRevenue;


      // --- 2. LẤY TỔNG SỐ LƯỢNG HỒ SƠ DANH MỤC ---

      final Map<String, dynamic> counts = {};

      final List<String> catalogTables = [
        'health_certifications',
        'prescriptions',
        'service_vouchers',
        'consulting_rooms',
        'medical_services',
        'medicine_types',
        'medicines',
        'patients',
      ];
      // Lượt khám đã xác nhận (Đếm List)
      final confirmedApps = await _supabase
          .from('appointments')
          .select('id')
          .eq('ngaydathen', today)
          .eq('trangthai', 'Đã xác nhận khám');
      final confirmedAppsCount = confirmedApps.length;

      // Lượt khám chờ xác nhận (Đếm List)
      final unconfirmedApps = await _supabase
          .from('appointments')
          .select('id')
          .eq('ngaydathen', today)
          .eq('trangthai', 'Chờ xác nhận');
      final unconfirmedAppsCount = unconfirmedApps.length;

      // Đếm Giấy Khám Bệnh hôm nay
      final certsToday = await _supabase
          .from('health_certifications')
          .select('id')
          .eq('ngay', today);
      final certsTodayCount = certsToday.length;

      // Đếm các danh mục khác (CHỈ CẦN SỬ DỤNG .length)
      final patientCount = (await _supabase.from('patients').select('id')).length;
      final serviceCount = (await _supabase.from('medical_services').select('id')).length;
      final prescriptionCount = (await _supabase.from('prescriptions').select('id')).length;
      final consRoomsCount = (await _supabase.from('consulting_rooms').select('id')).length;
      final medicineTypesCount = (await _supabase.from('medicine_types').select('id')).length;
      final medicinesCount = (await _supabase.from('medicines').select('id')).length;
      final servicevouchersCount = (await _supabase.from('service_vouchers').select('id')).length;


      return {
        'tong_doanhthu': totalRevenue,
        'doanhthu_giaykham': certRevenue,
        'doanhthu_phieudv': voucherRevenue,
        'doanhthu_donthuoc': prescriptionRevenue,
        'counts': {
          'patients': patientCount,
          'medical_services': serviceCount,
          'health_cert': certsTodayCount,
          'confirmed_apps': confirmedAppsCount,
          'unconfirmed_apps': unconfirmedAppsCount,
          'prescriptions': prescriptionCount,
          'consulting_rooms': consRoomsCount,
          'medicine_types': medicineTypesCount,
          'medicines': medicinesCount,
          'service_vouchers': servicevouchersCount,
        },

      };



    } catch (error) {
      throw Exception('Lỗi tải dữ liệu Dashboard: $error');
    }
  }


  Future<List<Map<String, dynamic>>> fetchDoctorsByRole(String roleName) async {
    try {
      final roleResponse = await _supabase.from('roles').select('id').eq('tenvaitro', roleName).single();
      final roleId = roleResponse['id'];

      // !!! CHỌN TẤT CẢ CÁC TRƯỜNG CẦN THIẾT
      final doctorsResponse = await _supabase
          .from('users')
          .select('auth_id, hovaten, sodienthoai, gioitinh, ngaysinh, diachi')
          .eq('role_id', roleId);

      return List<Map<String, dynamic>>.from(doctorsResponse);
    } catch (e) {
      print('Lỗi tải danh sách bác sĩ: $e');
      return [];
    }
  }
}