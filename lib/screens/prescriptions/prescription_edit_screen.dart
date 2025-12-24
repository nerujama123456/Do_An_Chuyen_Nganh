// lib/screens/prescriptions/prescription_edit_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/prescription_service.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../models/prescription_detail.dart';

class PrescriptionEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final String prescriptionId;

  const PrescriptionEditScreen({super.key, required this.onSave, required this.prescriptionId});

  @override
  _PrescriptionEditScreenState createState() => _PrescriptionEditScreenState();
}

class _PrescriptionEditScreenState extends State<PrescriptionEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final PrescriptionService _prescriptionService = PrescriptionService();
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();

  // Header fields
  int? _patientId;
  String? _patientName;
  String? _doctorName;

  // Data lists
  List<Map<String, dynamic>> _patientsList = [];
  List<Map<String, dynamic>> _availableMedicines = [];

  // Detail fields
  List<Map<String, dynamic>> _medicineDetails = [];

  bool _isLoading = true;
  String _currentPrescriptionId = '';

  @override
  void initState() {
    super.initState();
    _currentPrescriptionId = widget.prescriptionId;
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final headerFuture = _prescriptionService.getPrescriptionHeader(_currentPrescriptionId);
      final detailsFuture = _prescriptionService.getPrescriptionDetails(_currentPrescriptionId);
      final medicinesFuture = _dataService.fetchMedicines();
      final patientsFuture = _dataService.fetchPatients();

      final results = await Future.wait([headerFuture, detailsFuture, medicinesFuture, patientsFuture]);

      if (!mounted) return;

      final header = results[0] as Map<String, dynamic>;
      final details = results[1] as List<PrescriptionDetail>;

      setState(() {
        _patientId = header['patient_id'] as int?;
        _patientName = header['tenbenhnhan'];
        _doctorName = header['bacsi'];

        // CÁC TRƯỜNG CẦN CHỈNH SỬA
        // Cần lấy isbhyt từ database nếu có (giả định cột tồn tại)
        // _isBHYT = header['isbhyt'] ?? false;

        _availableMedicines = results[2] as List<Map<String, dynamic>>;
        _patientsList = results[3] as List<Map<String, dynamic>>;

        // Chuyển Model Detail sang Map
        _medicineDetails = details.map((d) => {
          'medicine_id': d.medicine_id,
          'tenthuoc': d.tenthuoc,
          'donvitinh': d.donvitinh,
          'soluong': d.soluong,
          'cachdung': d.cachdung,
          'giavnd': d.giavnd,
          'tongtien': d.tongtien,
        }).toList();

        // Đảm bảo có ít nhất một dòng trống nếu danh sách rỗng
        if (_medicineDetails.isEmpty) {
          _medicineDetails.add({});
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // HÀM: Thêm dòng chi tiết thuốc (ĐÃ SỬA)
  void _addMedicineDetailRow() {
    setState(() {
      _medicineDetails.add({});
    });
  }

  // HÀM: Xóa dòng chi tiết thuốc (ĐÃ SỬA)
  void _removeMedicineDetailRow(int index) {
    setState(() {
      _medicineDetails.removeAt(index);
    });
  }

  // HÀM: Cập nhật giá và đơn vị tính khi chọn thuốc (ĐÃ SỬA)
  void _updateMedicineFields(int index, int? medicineId) {
    if (medicineId == null) return;
    final medicine = _availableMedicines.firstWhere((m) => m['id'] == medicineId);

    _medicineDetails[index]['medicine_id'] = medicine['id'];
    _medicineDetails[index]['giavnd'] = medicine['giavnd'] ?? 0;
    _medicineDetails[index]['donvitinh'] = medicine['donvitinh'] ?? 'Viên';
    _medicineDetails[index]['tenthuoc'] = medicine['tenthuoc'];

    _calculateDetailTotal(index);
    setState(() {});
  }

  // HÀM: Tính tổng tiền cho một dòng (ĐÃ SỬA)
  void _calculateDetailTotal(int index) {
    final quantity = int.tryParse(_medicineDetails[index]['soluong']?.toString() ?? '0') ?? 0;
    final price = _medicineDetails[index]['giavnd'] ?? 0;
    _medicineDetails[index]['tongtien'] = quantity * price;
    setState(() {});
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // !!! TÍNH TỔNG TIỀN TỪ CỘT CHỮ THƯỜNG
      final totalAmount = _medicineDetails.fold<int>(
          0,
              (sum, detail) => sum + (detail['tongtien'] as int? ?? 0)
      );

      // 1. Dữ liệu Header
      final headerData = {
        'tongtien': totalAmount,

      };

      // 2. Dữ liệu Chi tiết (chuẩn hóa tên cột DB)
      final detailData = _medicineDetails.where((d) => d['medicine_id'] != null).map((detail) => {
        'prescription_id': int.parse(widget.prescriptionId),
        'medicine_id': detail['medicine_id'],
        'tenthuoc': detail['tenthuoc'],
        'donvitinh': detail['donvitinh'],
        'soluong': detail['soluong'],
        'cachdung': detail['cachdung'],
        'giavnd': detail['giavnd'],
        'tongtien': detail['tongtien'],
      }).toList();

      try {
        final success = await _prescriptionService.updatePrescription(widget.prescriptionId, headerData, detailData);

        if (mounted && success) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật đơn thuốc thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại.'), backgroundColor: Colors.red));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  // Hàm XÓA (Tùy chọn)
  void _deleteCert() async {
    // TODO: Triển khai hàm delete trong service
    bool success = true;
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa giấy khám bệnh thành công!'), backgroundColor: Colors.green));
      widget.onSave();
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Lấy tên bệnh nhân và bác sĩ từ biến đã tải
    final patient = _patientsList.firstWhere((p) => p['id'] == _patientId, orElse: () => {});
    final patientName = _patientName ?? 'N/A';
    final doctorName = _doctorName ?? 'N/A';
    final currentTitle = 'CẬP NHẬT ĐƠN THUỐC #${_currentPrescriptionId}';


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
                    Text(currentTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Phần 1: Thông tin Đơn thuốc chính (READ ONLY)
                    const Text('Thông tin đơn thuốc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Tên bệnh nhân (READ-ONLY TEXT)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextFormField(
                              initialValue: patientName,
                              decoration: InputDecoration(
                                labelText: 'Tên bệnh nhân (Không sửa)',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[300], // Bôi đen không cho sửa
                              ),
                              readOnly: true,
                              style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        const SizedBox(width: 20),
                        // Bác sĩ (READ-ONLY TEXT)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextFormField(
                              initialValue: doctorName,
                              decoration: InputDecoration(
                                labelText: 'Bác sĩ (Không sửa)',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[300], // Bôi đen không cho sửa
                              ),
                              readOnly: true,
                              style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Phần 2: Chi tiết Đơn thuốc (EDITABLE)
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
                          SizedBox(width: 48),
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
                                  hint: Text(_medicineDetails[index]['tenthuoc'] ?? 'Chọn thuốc'), // Hiển thị tên thuốc cũ
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                  items: _availableMedicines.map((med) {
                                    return DropdownMenuItem<int>(
                                      value: med['id'] as int,
                                      child: Text(med['tenthuoc']),
                                    );
                                  }).toList(),
                                  onChanged: (value) => _updateMedicineFields(index, value),
                                  validator: (value) => _medicineDetails[index]['medicine_id'] == null ? 'Chọn thuốc' : null,
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
                                  validator: (value) => (value == null || value.isEmpty || int.tryParse(value)! <= 0) ? 'Số lượng' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Cách dùng (TextFormField)
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: _medicineDetails[index]['cachdung'],
                                  decoration: const InputDecoration(labelText: 'Chỉ định cách dùng cho bệnh nhân', border: OutlineInputBorder()),
                                  onSaved: (value) => _medicineDetails[index]['cachdung'] = value,
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



                    // Nút Lưu/Quay lại
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}