// lib/screens/health_certs/health_cert_form_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/health_cert_service.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';

class HealthCertFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const HealthCertFormScreen({Key? key, required this.onSave}) : super(key: key);

  @override
  _HealthCertFormScreenState createState() => _HealthCertFormScreenState();
}

class _HealthCertFormScreenState extends State<HealthCertFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Khai báo các Service Instances
  final HealthCertService _healthCertService = HealthCertService();
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();

  // Header fields
  String _title = '';
  int? _selectedPatientId; // Lưu ID Bệnh nhân
  int? _selectedRoomId; // Lưu ID Phòng khám
  String? _selectedDoctorAuthId; // Lưu UUID Auth ID Bác sĩ
  String _price = '0';

  // Data lists
  List<Map<String, dynamic>> _patientsList = [];
  List<Map<String, dynamic>> _roomsList = [];
  List<Map<String, dynamic>> _doctorsList = [];
  Map<String, dynamic>? _currentDoctor;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      // Tải tất cả danh mục cần thiết từ DataService và AuthService
      final patientFuture = _dataService.fetchPatients();
      final roomFuture = _dataService.fetchConsultingRooms();
      final doctorFuture = _dataService.fetchDoctorsByRole('Bác sĩ');
      final currentDoctorFuture = _authService.getCurrentUserInfo();

      final results = await Future.wait([patientFuture, roomFuture, doctorFuture, currentDoctorFuture]);

      if (!mounted) return;

      final doctors = results[2] as List<Map<String, dynamic>>;
      final currentDoctor = results[3] as Map<String, dynamic>?;

      setState(() {
        _patientsList = results[0] as List<Map<String, dynamic>>;
        _roomsList = results[1] as List<Map<String, dynamic>>;
        _doctorsList = doctors;
        _currentDoctor = currentDoctor;

        // 1. Khởi tạo giá trị mặc định cho Bệnh nhân và Phòng khám
        if (_patientsList.isNotEmpty) {
          _selectedPatientId = _patientsList.first['id'] as int;
        }

        if (_roomsList.isNotEmpty) {
          _selectedRoomId = _roomsList.first['id'] as int;
          _updatePrice(_selectedRoomId);
        }

        // 2. Gán giá trị mặc định cho Bác sĩ
        if (_doctorsList.isNotEmpty) {
          // Ưu tiên chọn bác sĩ đăng nhập, nếu không chọn người đầu tiên
          final doctorToSelect = _doctorsList.any((d) => d['auth_id'] == currentDoctor?['auth_id'])
              ? _doctorsList.firstWhere((d) => d['auth_id'] == currentDoctor!['auth_id'])
              : _doctorsList.first;

          _selectedDoctorAuthId = doctorToSelect['auth_id'] as String;
        }

        _isDataLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu danh mục: $e')));
        setState(() => _isDataLoading = false);
      }
    }
  }


  void _updatePrice(int? roomId) {


    // Logic tính giá đơn giản dựa trên phòng khám
    final room = _roomsList.firstWhere((r) => r['id'] == roomId, orElse: () => <String, dynamic>{});



    setState(() {});
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Lấy tên bệnh nhân (chữ thường)
      final patientName = _patientsList.firstWhere((p) => p['id'] == _selectedPatientId)['hovaten'];

      // Dữ liệu đã được ánh xạ sang tên cột chữ thường của DB
      final dataToSend = {
        'ma': 'GKB${DateTime.now().millisecondsSinceEpoch}',
        'title': _title,
        'patient_id': _selectedPatientId,
        'tenbenhnhan': patientName,
        'phongkham_id': _selectedRoomId,
        'user_id': _selectedDoctorAuthId,
        'trangthai': 'Chưa khám',
        'thanhtoan': 'Chưa thanh toán',
        'ngay': DateTime.now().toString().substring(0, 10),
        'gia':  int.parse(_price),

      };

      final success = await _healthCertService.createHealthCertification(dataToSend);
      if (mounted) {
        if (success) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm giấy khám bệnh thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thất bại.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

                    const Text('THÊM GIẤY KHÁM BỆNH', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Điền tất cả thông tin bệnh dưới đây'),
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
                              // TRƯỜNG BỆNH NHÂN
                              child: DropdownButtonFormField<int>(
                                value: _selectedPatientId,
                                hint: const Text('Chọn bệnh nhân'),
                                decoration: const InputDecoration(labelText: 'Tên bệnh nhân *', border: OutlineInputBorder()),
                                items: _patientsList.map((patient) {
                                  return DropdownMenuItem<int>(
                                    value: patient['id'] as int,
                                    child: Text(patient['hovaten']),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedPatientId = value),
                                onSaved: (value) => _selectedPatientId = value,
                                validator: (value) => value == null ? 'Vui lòng chọn bệnh nhân' : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // TRƯỜNG PHÒNG KHÁM
                                  DropdownButtonFormField<int>(
                                    value: _selectedRoomId,
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
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Giá *', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _price = value ?? '',
                                validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                              ),
                            ),

                            const SizedBox(width: 20),
                            Expanded(
                              // TRƯỜNG BÁC SĨ
                              child: DropdownButtonFormField<String>(
                                value: _selectedDoctorAuthId,
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
                              child: const Text('Lưu lại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue, foregroundColor: Colors.white,
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