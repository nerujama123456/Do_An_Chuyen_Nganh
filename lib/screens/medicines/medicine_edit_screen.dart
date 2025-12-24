// lib/screens/medicines/medicine_edit_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';
import '../../models/medicine.dart';
import '../../models/medicine_type.dart';

class MedicineEditScreen extends StatefulWidget {
  final VoidCallback onSave;
  final int medicineId;

  const MedicineEditScreen({super.key, required this.onSave, required this.medicineId});

  @override
  _MedicineEditScreenState createState() => _MedicineEditScreenState();
}

class _MedicineEditScreenState extends State<MedicineEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  late Future<Map<String, dynamic>> _dataFuture;

  String _tenThuoc = '';
  String _moTa = '';
  int _giaVND = 0;
  String _donViTinh = '';
  int? _selectedTypeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadInitialData();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    final medicineFuture = _dataService.getMedicineDetail(widget.medicineId);
    final typesFuture = _dataService.fetchMedicineTypes();

    final results = await Future.wait([medicineFuture, typesFuture]);

    final Medicine medicine = results[0] as Medicine;
    final List<Map<String, dynamic>> typesMap = results[1] as List<Map<String, dynamic>>;

    // Gán giá trị ban đầu cho các biến trạng thái
    _tenThuoc = medicine.tenthuoc;
    _moTa = medicine.mota;
    _giaVND = medicine.giavnd;
    _donViTinh = medicine.donvitinh;
    _selectedTypeId = medicine.loaithuoc_id;

    return {
      'medicine': medicine,
      'typesList': typesMap.map((map) => MedicineType.fromJson(map)).toList(),
    };
  }

  void _submitForm(Medicine currentMedicine) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final success = await _dataService.updateMedicine(
            currentMedicine.id,
            _tenThuoc,
            _selectedTypeId!,
            _giaVND,
            _donViTinh,
            _moTa
        );

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            widget.onSave();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thuốc thành công!'), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại.'), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/medicines'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));

                  final Medicine medicine = snapshot.data!['medicine'] as Medicine;
                  final List<MedicineType> typesList = snapshot.data!['typesList'] as List<MedicineType>;

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHỈNH SỬA THUỐC #${medicine.ma}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Divider(),

                        const Text('Thông tin cơ bản', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Mã thuốc (READ ONLY)
                        TextFormField(
                          initialValue: medicine.ma,
                          decoration: InputDecoration(labelText: 'Mã Thuốc', border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey[200]),
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),

                        // Hàng 1: Tên Thuốc, Loại Thuốc
                        Row(
                          children: [
                            Expanded(
                              // Tên thuốc
                              child: TextFormField(
                                initialValue: medicine.tenthuoc,
                                decoration: const InputDecoration(labelText: 'Tên Thuốc *', border: OutlineInputBorder()),
                                onSaved: (value) => _tenThuoc = value ?? '',
                                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên thuốc' : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              // Loại thuốc (Dropdown)
                              child: DropdownButtonFormField<int>(
                                value: _selectedTypeId,
                                decoration: const InputDecoration(labelText: 'Loại Thuốc *', border: OutlineInputBorder()),
                                items: typesList.map((type) => DropdownMenuItem<int>(
                                  value: type.id,
                                  child: Text(type.tenloaithuoc),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedTypeId = value),
                                validator: (value) => value == null ? 'Vui lòng chọn loại thuốc' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Hàng 2: Giá, Đơn vị tính
                        Row(
                          children: [
                            Expanded(
                              // Giá
                              child: TextFormField(
                                initialValue: medicine.giavnd.toString(),
                                decoration: const InputDecoration(labelText: 'Giá (VND) *', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onSaved: (value) => _giaVND = int.tryParse(value ?? '0') ?? 0,
                                validator: (value) => value!.isEmpty || int.tryParse(value) == null ? 'Vui lòng nhập giá hợp lệ' : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              // Đơn vị tính
                              child: TextFormField(
                                initialValue: medicine.donvitinh,
                                decoration: const InputDecoration(labelText: 'Đơn vị tính *', border: OutlineInputBorder()),
                                onSaved: (value) => _donViTinh = value ?? '',
                                validator: (value) => value!.isEmpty ? 'Vui lòng nhập đơn vị tính' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Mô tả
                        TextFormField(
                          initialValue: medicine.mota,
                          decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                          onSaved: (value) => _moTa = value ?? '',
                        ),
                        const SizedBox(height: 30),

                        // Nút hành động
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _submitForm(medicine),
                              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cập nhật'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue, foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Quay lại'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}