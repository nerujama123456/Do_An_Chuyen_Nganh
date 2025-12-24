// lib/screens/service_vouchers/service_voucher_edit_screen.dart (File MỚI)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sidebar.dart';
import '../../services/service_voucher_service.dart';
import '../../services/data_service.dart';
import '../../models/service_voucher.dart';

class ServiceVoucherEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final String voucherId;

  const ServiceVoucherEditScreen({super.key, required this.onSave, required this.voucherId});

  @override
  _ServiceVoucherEditScreenState createState() => _ServiceVoucherEditScreenState();
}

class _ServiceVoucherEditScreenState extends State<ServiceVoucherEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceVoucherService _voucherService = ServiceVoucherService();
  final DataService _dataService = DataService();

  // Biến trạng thái Form
  String _ma = '';
  int? _selectedPatientId;
  String? _selectedDoctorAuthId;
  int? _selectedServiceId;

  DateTime? _startDate;
  DateTime? _endDate;
  String _price = '0';

  // Data lists
  List<Map<String, dynamic>> _patientsList = [];
  List<Map<String, dynamic>> _doctorsList = [];
  List<Map<String, dynamic>> _serviceList = [];
  bool _isLoading = true;

  final DateFormat formatter = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final voucherFuture = _voucherService.getServiceVoucherDetail(widget.voucherId);
      final doctorFuture = _dataService.fetchDoctorsByRole('Bác sĩ');
      final patientFuture = _dataService.fetchPatients();
      final serviceFuture = _dataService.fetchMedicalServices();

      final results = await Future.wait([voucherFuture, doctorFuture, patientFuture, serviceFuture]);

      if (!mounted) return;

      final ServiceVoucher voucher = results[0] as ServiceVoucher;

      setState(() {
        _doctorsList = results[1] as List<Map<String, dynamic>>;
        _patientsList = results[2] as List<Map<String, dynamic>>;
        _serviceList = results[3] as List<Map<String, dynamic>>;

        // Gán dữ liệu cũ
        _ma = voucher.ma;
        _selectedPatientId = voucher.patient_id;
        _selectedServiceId = voucher.dichvukham_id;
        _startDate = DateTime.tryParse(voucher.ngaybatdau);
        _endDate = DateTime.tryParse(voucher.ngayketthuc);



        // Tìm bác sĩ hiện tại
        _selectedDoctorAuthId = _doctorsList.firstWhere((d) => d['hovaten'] == voucher.bacsi, orElse: () => {})['auth_id'];

        // Cập nhật giá ban đầu
        _updatePrice(_selectedServiceId);

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu chỉnh sửa: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _updatePrice(int? serviceId) {
    final service = _serviceList.firstWhere((s) => s['id'] == serviceId, orElse: () => <String, dynamic>{});
    _price = service['giavnd']?.toString() ?? '0';
    setState(() {});
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      // Lấy trạng thái hiện tại (đã được tải trong _loadInitialData)
      final ServiceVoucher voucher = (await _voucherService.getServiceVoucherDetail(widget.voucherId));

      final patientName = _patientsList.firstWhere((p) => p['id'] == _selectedPatientId)['hovaten'];

      final dataToSend = {
        // !!! CÁC TRƯỜNG CÓ THỂ SỬA
        'patient_id': _selectedPatientId,
        'tenbenhnhan': patientName,
        'dichvukham_id': _selectedServiceId,
        'user_id': _selectedDoctorAuthId,
        'ngaybatdau': _startDate?.toIso8601String().substring(0, 10),
        'ngayketthuc': _endDate?.toIso8601String().substring(0, 10),
        'tongtien':   int.parse(_price),

        // !!! CÁC TRƯỜNG CHỈ ĐỌC (Được giữ nguyên giá trị cũ)
        'ma': voucher.ma,
        'trangthai': voucher.trangthai,
        'thanhtoan': voucher.thanhtoan,
      };

      try {
        final success = await _voucherService.updateServiceVoucher(widget.voucherId, dataToSend);
        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật phiếu dịch vụ thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại.'), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: ${e.toString()}'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final String currentTitle = 'CHỈNH SỬA PHIẾU DỊCH VỤ #${_ma}';

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
                    Text(currentTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Hàng 0: Mã Phiếu (READ ONLY)
                    TextFormField(
                      initialValue: _ma,
                      decoration:  InputDecoration(labelText: 'Mã Phiếu Dịch Vụ', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[300]),
                      readOnly: true,
                      style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                    ),
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
                      // Khoảng trống (Đã bỏ Phòng khám)
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

                    // Hàng 3: Ngày bắt đầu, Giá, Trạng thái (READ ONLY)
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
                      // Trạng thái (READ ONLY)

                    ]),
                    const SizedBox(height: 30),

                    // Nút hành động
                    Row(children: [
                      ElevatedButton(onPressed: _submitForm, child: const Text('Cập nhật'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
                      ),
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