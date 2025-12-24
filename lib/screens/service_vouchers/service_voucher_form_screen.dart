// lib/screens/service_vouchers/service_voucher_form_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/service_voucher_service.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class ServiceVoucherFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const ServiceVoucherFormScreen({super.key, required this.onSave});

  @override
  _ServiceVoucherFormScreenState createState() => _ServiceVoucherFormScreenState();
}

class _ServiceVoucherFormScreenState extends State<ServiceVoucherFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final ServiceVoucherService _voucherService = ServiceVoucherService();
  final DataService _dataService = DataService();

  // Header fields
  int? _selectedPatientId;
  String? _selectedDoctorAuthId;
  int? _selectedServiceId;
  // !!! ĐÃ BỎ: int? _selectedRoomId;

  DateTime? _startDate = DateTime.now();
  DateTime? _endDate = DateTime.now().add(const Duration(days: 1));

  // Data lists
  List<Map<String, dynamic>> _patientsList = [];
  // !!! ĐÃ BỎ: List<Map<String, dynamic>> _roomsList = [];
  List<Map<String, dynamic>> _doctorsList = [];
  List<Map<String, dynamic>> _serviceList = [];
  bool _isDataLoading = true;
  String _price = '0';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final patientFuture = _dataService.fetchPatients();
      final doctorFuture = _dataService.fetchDoctorsByRole('Bác sĩ');
      // !!! ĐÃ XÓA FUTURE CỦA PHÒNG KHÁM
      final serviceFuture = _dataService.fetchMedicalServices();

      // Điều chỉnh Future.wait để chỉ chờ 3 Future
      final results = await Future.wait([patientFuture, doctorFuture, serviceFuture]);

      if (!mounted) return;

      setState(() {
        _patientsList = results[0] as List<Map<String, dynamic>>;
        _doctorsList = results[1] as List<Map<String, dynamic>>;
        _serviceList = results[2] as List<Map<String, dynamic>>;

        // Khởi tạo giá trị mặc định cho Dropdown
        if (_patientsList.isNotEmpty) _selectedPatientId = _patientsList.first['id'] as int;
        if (_doctorsList.isNotEmpty) _selectedDoctorAuthId = _doctorsList.first['auth_id'] as String;
        if (_serviceList.isNotEmpty) _selectedServiceId = _serviceList.first['id'] as int;

        _updatePrice(_selectedServiceId); // Tính giá ban đầu

        _isDataLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu danh mục: $e')));
        setState(() => _isDataLoading = false);
      }
    }
  }

  void _updatePrice(int? serviceId) {

    // Logic tính giá dựa trên ID Dịch vụ
    final service = _serviceList.firstWhere((s) => s['id'] == serviceId, orElse: () => <String, dynamic>{});
    _price = service['giavnd']?.toString() ?? '0';

    setState(() {});
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final patientName = _patientsList.firstWhere((p) => p['id'] == _selectedPatientId)['hovaten'];

      // Chuẩn bị data theo tên cột chữ thường của DB
      final dataToSend = {
        'ma': 'PDV${DateTime.now().millisecondsSinceEpoch}',
        'patient_id': _selectedPatientId,
        'tenbenhnhan': patientName,
        'dichvukham_id': _selectedServiceId,
        // !!! ĐÃ BỎ: 'phongkham_id'
        'user_id': _selectedDoctorAuthId,
        'ngaybatdau': _startDate?.toIso8601String().substring(0, 10),
        'ngayketthuc': _endDate?.toIso8601String().substring(0, 10),
        'tongtien':  int.parse(_price),
        'trangthai': 'Chưa khám xong',
        'thanhtoan': 'Chưa thanh toán',
      };

      final success = await _voucherService.createServiceVoucher(dataToSend);
      if (mounted) {
        if (success) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm phiếu dịch vụ thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thất bại.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final DateFormat formatter = DateFormat('dd-MM-yyyy');

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/service_vouchers'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÊM PHIẾU DỊCH VỤ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Hàng 1: Bệnh nhân, BHYT, Bác sĩ
                    Row(children: [
                      // Tên bệnh nhân
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedPatientId,
                          decoration: const InputDecoration(labelText: 'Tên bệnh nhân *', border: OutlineInputBorder()),
                          items: _patientsList.map((patient) => DropdownMenuItem<int>(value: patient['id'] as int, child: Text(patient['hovaten']))).toList(),
                          onChanged: (value) => setState(() => _selectedPatientId = value),
                          validator: (value) => value == null ? 'Trường bắt buộc' : null,
                        ),
                      ),

                      const SizedBox(width: 20),
                      // Bác sĩ
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDoctorAuthId,
                          decoration: const InputDecoration(labelText: 'Bác sĩ *', border: OutlineInputBorder()),
                          items: _doctorsList.map((doctor) => DropdownMenuItem<String>(value: doctor['auth_id'] as String, child: Text(doctor['hovaten']))).toList(),
                          onChanged: (value) => setState(() => _selectedDoctorAuthId = value),
                          validator: (value) => value == null ? 'Trường bắt buộc' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Hàng 2: Dịch vụ, [Phòng khám đã bị xóa], Ngày kết thúc
                    Row(children: [
                      // Dịch vụ
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedServiceId,
                          decoration: const InputDecoration(labelText: 'Dịch vụ khám *', border: OutlineInputBorder()),
                          items: _serviceList.map((service) => DropdownMenuItem<int>(value: service['id'] as int, child: Text(service['tendichvu']))).toList(),
                          onChanged: (value) {setState(() => _selectedServiceId = value); _updatePrice(value);},
                          validator: (value) => value == null ? 'Trường bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // !!! THAY PHÒNG KHÁM BẰNG CỘT DƯ (ĐỂ GIỮ BỐ CỤC)
                      const Expanded(child: SizedBox()),
                      const SizedBox(width: 20),
                      // Ngày kết thúc
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(text: _endDate == null ? 'Chọn ngày' : formatter.format(_endDate!)),
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime(2028));
                            if (date != null) setState(() => _endDate = date);
                          },
                          decoration: const InputDecoration(labelText: 'Ngày kết thúc *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                          validator: (value) => _endDate == null ? 'Trường bắt buộc' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Hàng 3: Ngày bắt đầu, Giá
                    Row(children: [
                      // Ngày bắt đầu
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(text: _startDate == null ? 'Chọn ngày' : formatter.format(_startDate!)),
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime(2028));
                            if (date != null) setState(() => _startDate = date);
                          },
                          decoration: const InputDecoration(labelText: 'Ngày bắt đầu *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                          validator: (value) => _startDate == null ? 'Trường bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Giá
                      const Text('Tổng tiền = ', style: TextStyle(fontWeight: FontWeight.normal)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                              child: Text('$_price VND'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(child: SizedBox()), // Dư 1 cột
                    ]),
                    const SizedBox(height: 30),

                    // Nút hành động
                    Row(children: [
                      ElevatedButton(onPressed: _submitForm, child: const Text('Lưu lại'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)),
                      const SizedBox(width: 10),
                      OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
                    ]),
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