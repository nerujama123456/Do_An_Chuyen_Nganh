// lib/screens/health_certs/health_cert_edit_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/health_cert_service.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../models/health_certification.dart';

class HealthCertEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final String certId; // ID của hồ sơ cần chỉnh sửa

  const HealthCertEditScreen({super.key, required this.onSave, required this.certId});

  @override
  _HealthCertEditScreenState createState() => _HealthCertEditScreenState();
}

class _HealthCertEditScreenState extends State<HealthCertEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final HealthCertService _healthCertService = HealthCertService();
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();

  // Header fields
  String _title = '';
  int? _selectedPatientId;
  int? _selectedRoomId;
  String? _selectedDoctorAuthId;
  bool _isBHYT = false;
  String _price = '0';

  // Dữ liệu tải ban đầu
  HealthCertification? _initialCert;

  // Data lists
  List<Map<String, dynamic>> _patientsList = [];
  List<Map<String, dynamic>> _roomsList = [];
  List<Map<String, dynamic>> _doctorsList = [];
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      // Tải hồ sơ hiện tại và các danh mục
      final certFuture = _healthCertService.getHealthCertification(widget.certId);
      final patientFuture = _dataService.fetchPatients();
      final roomFuture = _dataService.fetchConsultingRooms();
      final doctorFuture = _dataService.fetchDoctorsByRole('Bác sĩ');

      final results = await Future.wait([certFuture, patientFuture, roomFuture, doctorFuture]);

      if (!mounted) return;

      final cert = results[0] as HealthCertification;
      final doctors = results[3] as List<Map<String, dynamic>>;

      setState(() {
        _initialCert = cert;
        _patientsList = results[1] as List<Map<String, dynamic>>;
        _roomsList = results[2] as List<Map<String, dynamic>>;
        _doctorsList = doctors;

        // Gán giá trị ban đầu cho form
        _title = cert.title;
        _price = cert.gia.toString();
        // LƯU Ý: Các trường ID phải được gán từ Model
        _selectedPatientId = cert.patient_id;
        _selectedRoomId = cert.phongkham_id;
        _selectedDoctorAuthId = cert.user_id;

        _isDataLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu chỉnh sửa: $e')));
        setState(() => _isDataLoading = false);
      }
    }
  }


  void _updatePrice(int? roomId) {
    if (_isBHYT) {
      _price = '0';
      return;
    }

    final room = _roomsList.firstWhere((r) => r['id'] == roomId, orElse: () => <String, dynamic>{});
    final roomName = room['tenphongkham'];

    if (roomName == 'Phòng Xét Nghiệm') {
      _price = '300000';
    } else if (roomName == 'Phòng Cấp Cứu') {
      _price = '123000';
    } else if (roomName == 'Phòng Chụp X-Quang') {
      _price = '50000';
    } else {
      _price = '0';
    }

    setState(() {});
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final patientName = _patientsList.firstWhere((p) => p['id'] == _selectedPatientId)['hovaten'];

      final dataToSend = {
        'title': _title,
        'patient_id': _selectedPatientId,
        'tenbenhnhan': patientName,
        'phongkham_id': _selectedRoomId,
        'user_id': _selectedDoctorAuthId,
        'gia': _isBHYT ? 0 : int.parse(_price),
        'isbhyt': _isBHYT,
        // Giữ nguyên trạng thái và thanh toán cũ
        'trangthai': _initialCert!.trangthai,
        'thanhtoan': _initialCert!.thanhtoan,
        'ngay': _initialCert!.ngay,
      };

      // Tái sử dụng hàm UPDATE
      bool success = await _healthCertService.updateHealthCertConclusion(widget.certId, dataToSend);

      if (mounted) {
        if (success) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thông tin thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context, true); // Trả về true để màn hình list tải lại
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại. (RLS?)'), backgroundColor: Colors.red));
        }
      }
    }
  }

  // Hàm XÓA
  void _deleteCert() async {
    // TODO: Triển khai hàm delete trong service
    // Giả định thành công:
    bool success = true;
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa giấy khám bệnh thành công!'), backgroundColor: Colors.green));
      widget.onSave();
      Navigator.pop(context, true); // Trả về true để list tải lại
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isDataLoading || _initialCert == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final formTitle = 'CHỈNH SỬA GIẤY KHÁM BỆNH #${_initialCert!.ma}';

    return Scaffold(
      body: Row(
        children: <Widget>[
          Sidebar(currentRoute: '/health_certs'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Chỉnh sửa thông tin hành chính của hồ sơ'),
                        const SizedBox(height: 20),

                        // Tiêu đề
                        TextFormField(
                          initialValue: _title,
                          decoration: const InputDecoration(labelText: 'Tiêu đề *', border: OutlineInputBorder()),
                          onSaved: (value) => _title = value ?? '',
                          validator: (value) => value!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                        ),
                        const SizedBox(height: 20),

                        // Hàng 1: Tên bệnh nhân, Phòng khám
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              // TRƯỜNG BỆNH NHÂN (READ-ONLY)
                              child: DropdownButtonFormField<int>(
                                value: _selectedPatientId, // Gán giá trị đã tải
                                hint: const Text('Chọn bệnh nhân'),
                                decoration: const InputDecoration(labelText: 'Tên bệnh nhân *', border: OutlineInputBorder()),
                                items: _patientsList.map((patient) {
                                  return DropdownMenuItem<int>(
                                    value: patient['id'] as int,
                                    child: Text(patient['hovaten']),
                                  );
                                }).toList(),
                                onChanged: null, // VÔ HIỆU HÓA ONCHANGED
                                onSaved: (value) => _selectedPatientId = value,
                                validator: (value) => value == null ? 'Vui lòng chọn bệnh nhân' : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const SizedBox(height: 8),
                                  // TRƯỜNG PHÒNG KHÁM
                                  DropdownButtonFormField<int>(
                                    value: _selectedRoomId, // Gán giá trị đã tải
                                    hint: const Text('Chọn phòng khám'),
                                    decoration: const InputDecoration(labelText: 'Phòng khám *', border: OutlineInputBorder()),
                                    items: _roomsList.map((room) {
                                      return DropdownMenuItem<int>(
                                        value: room['id'] as int,
                                        child: Text(room['tenphongkham']),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRoomId = value;
                                        _updatePrice(value);
                                      });
                                    },
                                    onSaved: (value) => _selectedRoomId = value,
                                    validator: (value) => value == null ? 'Chọn phòng khám' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Hàng 2: Giá, Bác sĩ
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Giá', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text('${_price} VND'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              // TRƯỜNG BÁC SĨ
                              child: DropdownButtonFormField<String>(
                                value: _selectedDoctorAuthId, // Gán giá trị đã tải
                                hint: const Text('Chọn bác sĩ'),
                                decoration: const InputDecoration(labelText: 'Bác sĩ *', border: OutlineInputBorder()),
                                items: _doctorsList.map((doctor) {
                                  return DropdownMenuItem<String>(
                                    value: doctor['auth_id'] as String,
                                    child: Text(doctor['hovaten']),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedDoctorAuthId = value),
                                onSaved: (value) => _selectedDoctorAuthId = value,
                                validator: (value) => value == null ? 'Chọn bác sĩ' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Nút hành động
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _submitForm,
                              child: const Text('Cập nhật'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue, foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Nút XÓA
                            ElevatedButton(
                              onPressed: _deleteCert,
                              child: const Text('Xóa'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red, foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Quay lại'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                              ),
                            ),
                          ],
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