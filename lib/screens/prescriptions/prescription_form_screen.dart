// lib/screens/prescriptions/prescription_form_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/prescription_service.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const PrescriptionFormScreen({super.key, required this.onSave});

  @override
  _PrescriptionFormScreenState createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final PrescriptionService _prescriptionService = PrescriptionService();
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();

  // Header fields
  int? _selectedPatientId;
  String? _selectedDoctorAuthId;

  // Data lists
  List<Map<String, dynamic>> _patientsList = [];
  List<Map<String, dynamic>> _doctorsList = [];
  List<Map<String, dynamic>> _availableMedicines = [];
  Map<String, dynamic>? _currentDoctor;

  // Detail fields (Sử dụng tên biến chữ thường)
  List<Map<String, dynamic>> _medicineDetails = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final patientFuture = _dataService.fetchPatients();
      final doctorFuture = _dataService.fetchDoctorsByRole('Bác sĩ');
      final currentDoctorFuture = _authService.getCurrentUserInfo();
      final medicinesFuture = _dataService.fetchMedicines();

      final results = await Future.wait([patientFuture, doctorFuture, currentDoctorFuture, medicinesFuture]);

      if (!mounted) return;

      final doctors = results[1] as List<Map<String, dynamic>>;
      final currentDoctor = results[2] as Map<String, dynamic>?;

      setState(() {
        _patientsList = results[0] as List<Map<String, dynamic>>;
        _doctorsList = doctors;
        _availableMedicines = results[3] as List<Map<String, dynamic>>;

        if (_patientsList.isNotEmpty) {
          _selectedPatientId = _patientsList.first['id'] as int;
        }

        if (_doctorsList.isNotEmpty) {
          final doctorToSelect = _doctorsList.firstWhere(
                  (d) => d['auth_id'] == currentDoctor?['auth_id'],
              orElse: () => _doctorsList.first
          );
          _selectedDoctorAuthId = doctorToSelect['auth_id'] as String;
        }

        _medicineDetails.add({});

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu danh mục: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // Thêm/Xóa Chi tiết thuốc
  void _addMedicineDetailRow() {
    setState(() {
      _medicineDetails.add({});
    });
  }

  void _removeMedicineDetailRow(int index) {
    setState(() {
      _medicineDetails.removeAt(index);
    });
  }

  // Cập nhật giá và đơn vị tính khi chọn thuốc
  void _updateMedicineFields(int index, int? medicineId) {
    if (medicineId == null) return;
    final medicine = _availableMedicines.firstWhere((m) => m['id'] == medicineId);

    // Gán ID, tên, giá, đơn vị tính (sử dụng tên biến chữ thường)
    _medicineDetails[index]['medicine_id'] = medicine['id'];
    _medicineDetails[index]['giavnd'] = medicine['giavnd'] ?? 0;
    _medicineDetails[index]['donvitinh'] = medicine['donvitinh'] ?? 'Viên';
    _medicineDetails[index]['tenthuoc'] = medicine['tenthuoc'];

    _calculateDetailTotal(index);
    setState(() {});
  }

  // Tính tổng tiền cho một dòng
  void _calculateDetailTotal(int index) {
    // SỬ DỤNG TÊN BIẾN CHỮ THƯỜNG
    final quantity = int.tryParse(_medicineDetails[index]['soluong']?.toString() ?? '0') ?? 0;
    final price = _medicineDetails[index]['giavnd'] ?? 0;
    _medicineDetails[index]['tongtien'] = quantity * price;
    setState(() {});
  }

  // Submit Form và lưu vào Supabase
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final totalAmount = _medicineDetails.fold<int>(
          0,
          // SỬ DỤNG TÊN BIẾN CHỮ THƯỜNG
              (sum, detail) => sum + (detail['tongtien'] as int? ?? 0)
      );

      final patientName = _patientsList.firstWhere((p) => p['id'] == _selectedPatientId)['hovaten'];

      // 1. Dữ liệu Header
      final headerData = {
        'ma': 'DT${DateTime.now().millisecondsSinceEpoch}',
        'patient_id': _selectedPatientId,
        'tenbenhnhan': patientName,
        'user_id': _selectedDoctorAuthId,
        'tongtien': totalAmount,
        'trangthai': 'Chưa mua',
      };

      // 2. Dữ liệu Chi tiết (chuẩn hóa tên cột DB)
      final detailData = _medicineDetails.where((d) => d['medicine_id'] != null).map((detail) => {
        'medicine_id': detail['medicine_id'],
        'tenthuoc': detail['tenthuoc'],
        'donvitinh': detail['donvitinh'],
        'soluong': detail['soluong'],
        'cachdung': detail['cachdung'],
        'giavnd': detail['giavnd'],
        'tongtien': detail['tongtien'],
      }).toList();

      final success = await _prescriptionService.createPrescription(headerData, detailData);

      if (mounted) {
        if (success) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đơn thuốc đã được tạo thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu đơn thuốc thất bại.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/prescriptions'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÊM ĐƠN THUỐC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Phần 1: Thông tin Đơn thuốc chính
                    const Text('Thông tin đơn thuốc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Điền tất cả thông tin bên dưới', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          // Tên bệnh nhân
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

                        const SizedBox(width: 20),
                        Expanded(
                          // Bác sĩ
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
                            validator: (value) => value == null ? 'Vui lòng chọn bác sĩ' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Phần 2: Chi tiết Đơn thuốc
                    const Text('Chi tiết đơn thuốc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Header chi tiết
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text('Tên thuốc', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 1, child: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text('Cách dùng', style: TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(width: 48), // Khoảng trống cho nút xóa
                        ],
                      ),
                    ),

                    // Danh sách Chi tiết thuốc (Dynamic List)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _medicineDetails.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            children: [
                              // Tên Thuốc (Dropdown)
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: _medicineDetails[index]['medicine_id'],
                                  hint: const Text('Chọn thuốc'),
                                  items: _availableMedicines.map((med) {
                                    return DropdownMenuItem<int>(
                                      value: med['id'] as int,
                                      child: Text(med['tenthuoc']),
                                    );
                                  }).toList(),
                                  onChanged: (value) => _updateMedicineFields(index, value),
                                  // Validator đã được đơn giản hóa
                                  validator: (value) => (_medicineDetails.length > 1 && value == null) || (index == 0 && value == null) ? 'Trường bắt buộc' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Số lượng (TextFormField)
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: _medicineDetails[index]['soluong']?.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Số lượng', border: OutlineInputBorder()),
                                  onChanged: (value) {
                                    _medicineDetails[index]['soluong'] = int.tryParse(value);
                                    _calculateDetailTotal(index);
                                  },
                                  onSaved: (value) => _medicineDetails[index]['soluong'] = int.tryParse(value ?? '0'),
                                  validator: (value) => (value == null || value.isEmpty || int.tryParse(value)! <= 0) ? 'Trường bắt buộc' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Cách dùng (TextFormField)
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'Chỉ định cách dùng cho bệnh nhân', border: OutlineInputBorder()),
                                  onSaved: (value) => _medicineDetails[index]['cachdung'] = value,
                                    validator: (value) =>  value!.isEmpty ? 'Trường bắt buộc' : null
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Thao tác (Nút Xóa dòng)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: _medicineDetails.length > 1 ? () => _removeMedicineDetailRow(index) : null,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    ElevatedButton.icon(
                      onPressed: _addMedicineDetailRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: 30),

                    // Nút Lưu/Quay lại
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Lưu lại'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)

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
              ),
            ),
          ),
        ],
      ),
    );
  }
}