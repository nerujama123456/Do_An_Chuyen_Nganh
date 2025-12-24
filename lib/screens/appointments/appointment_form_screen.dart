// lib/screens/appointments/appointment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/sidebar.dart';
import '../../services/data_service.dart';

class AppointmentFormScreen extends StatefulWidget {
  final VoidCallback onSave;

  const AppointmentFormScreen({super.key, required this.onSave});

  @override
  _AppointmentFormScreenState createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();

  // Biến trạng thái Form
  int? _patientId;
  String _gioiTinh = 'Nam';
  DateTime? _ngaySinh;
  String _lyDoKham = '';
  DateTime _ngayDatHen = DateTime.now();
  TimeOfDay _gioDatHen = TimeOfDay.now();

  // Trạng thái Checkbox
  bool _isXacNhanKham = false;

  // Danh mục
  List<Map<String, dynamic>> _doctorsList = [];
  String? _selectedDoctorAuthId;

  bool _isLoading = true;
  String _phoneSearchQuery = '';
  // !!! BIẾN KIỂM SOÁT READONLY CHO THÔNG TIN BỆNH NHÂN
  bool _isPatientInfoReadOnly = false;

  final DateFormat formatter = DateFormat('dd-MM-yyyy');

  // Khai báo Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }


  void _loadDoctors() async {
    try {
      final doctors = await _dataService.fetchDoctorsByRole('Bác sĩ');
      if (!mounted) return;
      setState(() {
        _doctorsList = doctors;
        if (doctors.isNotEmpty) {
          _selectedDoctorAuthId = doctors.first['auth_id'] as String;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _searchPatient() async {
    FocusScope.of(context).unfocus();
    final phoneToSearch = _phoneSearchQuery.replaceAll(RegExp(r'\D'), '');

    if (phoneToSearch.length < 10|| phoneToSearch.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ 10 chữ số điện thoại.')));
      return;
    }

    final results = await _dataService.searchPatientByPhone(phoneToSearch);

    if (mounted) {
      if (results.isNotEmpty) {
        _showPatientSelectionDialog(results.first);
      } else {
        // Nếu không tìm thấy, reset trạng thái
        setState(() {
          _isPatientInfoReadOnly = false;
          _patientId = null;
          _nameController.clear();
          _phoneController.text = _phoneSearchQuery;
          _addressController.clear();
          _ngaySinh = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy bệnh nhân cũ, vui lòng nhập thông tin mới.')));
      }
    }
  }

  void _showPatientSelectionDialog(Map<String, dynamic> patient) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông tin tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Số điện thoại ${patient['sodienthoai']} đã được sử dụng.'),
              const Divider(),
              Text('Họ và tên: ${patient['hovaten']}'),
              Text('Giới tính: ${patient['gioitinh']}'),
              Text('Ngày sinh: ${patient['ngaysinh']}'),
              Text('Địa chỉ: ${patient['diachi']}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, 2), child: const Text('Không chọn', style: TextStyle(color: Colors.red))),
            TextButton(onPressed: () => Navigator.pop(context, 1), child: const Text('Chọn', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        )
    ).then((selection) {
      if (selection == 1) {
        // LOGIC ĐÃ SỬA: Gán tất cả thông tin form cần thiết
        setState(() {
          _isPatientInfoReadOnly = true;
          _patientId = patient['id'] as int;

          // Cập nhật các biến read-only (để hiển thị)
          _gioiTinh = patient['gioitinh'];
          _ngaySinh = DateTime.tryParse(patient['ngaysinh'] ?? '');

          // Cập nhật Controllers (Sẽ bị bôi xám và không sửa được)
          _nameController.text = patient['hovaten'];
          _phoneController.text = patient['sodienthoai'];
          _addressController.text = patient['diachi'];
        });
      }
    });
  }


  void _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final hoVaTen = _nameController.text;
    final soDienThoai = _phoneController.text;
    final diaChi = _addressController.text;

    final ngaySinhString = _ngaySinh?.toIso8601String().substring(0, 10);
    final gioDatHenString = DateFormat('HH:mm').format(DateTime(_ngayDatHen.year, _ngayDatHen.month, _ngayDatHen.day, _gioDatHen.hour, _gioDatHen.minute));

    int? finalPatientId = _patientId;

    // BƯỚC 1: XỬ LÝ BỆNH NHÂN MỚI (Nếu không tìm thấy hồ sơ cũ)
    if (finalPatientId == null) {
      final newPatientData = {
        'ma': 'BN${DateTime.now().millisecondsSinceEpoch}',
        'hovaten': hoVaTen,
        'gioitinh': _gioiTinh,
        'sodienthoai': soDienThoai,
        'diachi': diaChi,
        'ngaysinh': ngaySinhString,
      };

      try {
        // GỌI HÀM TẠO HỒ SƠ VÀ LẤY ID
        finalPatientId = await _dataService.createPatientAndGetId(newPatientData);

      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo hồ sơ BN: ${e.toString()}'), backgroundColor: Colors.red));
          return;
        }
      }
    }

    // BƯỚC 2: TẠO LỊCH HẸN
    final data = {
      // !!! SỬ DỤNG finalPatientId
      'patient_id': finalPatientId,
      'hovaten': hoVaTen,
      'gioitinh': _gioiTinh,
      'sodienthoai': soDienThoai,
      'diachi': diaChi,
      'ngaysinh': ngaySinhString,

      'bacsi_id': _selectedDoctorAuthId,
      'ngaydathen': _ngayDatHen.toIso8601String().substring(0, 10),
      'giodathen': gioDatHenString,
      'lydokham': _lyDoKham,
      'trangthai': _isXacNhanKham ? 'Đã xác nhận khám' : 'Chờ xác nhận',
    };

    try {
      final success = await _dataService.createAppointment(data);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm đặt hẹn khám bệnh thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt hẹn thất bại: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  // Widget TextFormField tùy chỉnh cho chế độ ReadOnly
  Widget _buildCustomTextField({
    required String labelText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    IconData? suffixIcon,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,

  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
      ),
      style: TextStyle(color: readOnly ? Colors.black54 : Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/patients'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TẠO ĐẶT HẸN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Khối 1: Thông tin bệnh nhân & Chỉ số sinh tồn
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cột 1: Thông tin bệnh nhân (Patient Info)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thông tin bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              // Họ và tên
                              _buildCustomTextField(
                                labelText: 'Họ và tên *',
                                controller: _nameController,
                                readOnly: _isPatientInfoReadOnly, // Bôi xám
                                onSaved: (value) { /* Lấy từ controller trong submit */ },
                                validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                              ),
                              const SizedBox(height: 10),
                              // Số điện thoại (TÌM KIẾM)
                              Row(children: [
                                Expanded(
                                  child: _buildCustomTextField(
                                    labelText: 'Số điện thoại *',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    readOnly: _isPatientInfoReadOnly, // Bôi xám
                                    onSaved: (value) { /* Lấy từ controller trong submit */ },
                                    onChanged: (value) => _phoneSearchQuery = value,
                                    validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isPatientInfoReadOnly ? null : _searchPatient,
                                  child: const Text('Tìm'), style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,)
                                ),
                              ]),
                              const SizedBox(height: 10),
                              // Giới tính và Ngày sinh
                              Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Giới tính *', style: TextStyle(fontWeight: FontWeight.w600)),
                                      Row(
                                        children: [
                                          // !!! RADIO BUTTONS BỊ BÔI XÁM VÌ SỬ DỤNG _isPatientInfoReadOnly
                                          Radio<String>(value: 'Nam', groupValue: _gioiTinh, onChanged: _isPatientInfoReadOnly ? null : (v) => setState(() => _gioiTinh = v!)),
                                          Text('Nam', style: TextStyle(color: _isPatientInfoReadOnly ? Colors.black54 : Colors.black)),
                                          Radio<String>(value: 'Nữ', groupValue: _gioiTinh, onChanged: _isPatientInfoReadOnly ? null : (v) => setState(() => _gioiTinh = v!)),
                                          Text('Nữ', style: TextStyle(color: _isPatientInfoReadOnly ? Colors.black54 : Colors.black)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _buildCustomTextField(
                                    labelText: 'Ngày sinh *',
                                    controller: TextEditingController(text: _ngaySinh == null ? '' : formatter.format(_ngaySinh!)),
                                    readOnly: _isPatientInfoReadOnly,
                                    onTap: _isPatientInfoReadOnly ? null : () async {
                                      final date = await showDatePicker(context: context, initialDate: _ngaySinh ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                                      if (date != null) setState(() => _ngaySinh = date);
                                    },
                                    suffixIcon: Icons.calendar_today,
                                    validator: (value) => _ngaySinh == null ? 'Trường bắt buộc' : null,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              // Địa chỉ
                              _buildCustomTextField(
                                labelText: 'Địa chỉ *',
                                controller: _addressController,
                                readOnly: _isPatientInfoReadOnly,
                                onSaved: (value) { /* Giá trị được lấy từ controller */ },
                                validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),

                      ],
                    ),
                    const Divider(height: 40),

                    // Khối 2: Thông tin đặt khám
                    const Text('Thông tin đặt khám', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cột 1: Bác sĩ, Ngày/Giờ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bác sĩ
                              DropdownButtonFormField<String>(
                                value: _selectedDoctorAuthId,
                                decoration: const InputDecoration(labelText: 'Bác sĩ *', border: OutlineInputBorder()),
                                items: _doctorsList.map((doctor) => DropdownMenuItem<String>(value: doctor['auth_id'] as String, child: Text(doctor['hovaten']))).toList(),
                                onChanged: (v) => setState(() => _selectedDoctorAuthId = v),
                                validator: (v) => v == null ? 'Chọn bác sĩ' : null,
                                onSaved: (v) => _selectedDoctorAuthId = v,
                              ),
                              const SizedBox(height: 10),
                              // Ngày đặt hẹn
                              // !!! TRƯỜNG NGÀY ĐẶT HẸN ĐÃ SỬA
                              TextFormField(
                                readOnly: true,
                                controller: TextEditingController(text: formatter.format(_ngayDatHen)),
                                onTap: () async {
                                  final date = await showDatePicker(context: context, initialDate: _ngayDatHen, firstDate: DateTime.now(), lastDate: DateTime(2028));
                                  if (date != null) setState(() => _ngayDatHen = date);
                                },
                                decoration: const InputDecoration(labelText: 'Ngày đặt hẹn *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                                validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                                // LOẠI BỎ THUỘC TÍNH FILLED/FILLCOLOR VÀ READONLY
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 10),
                              // Giờ đặt hẹn
                              // !!! TRƯỜNG GIỜ ĐẶT HẸN ĐÃ SỬA
                              TextFormField(
                                readOnly: true,
                                controller: TextEditingController(text: _gioDatHen.format(context)),
                                onTap: () async {
                                  final time = await showTimePicker(context: context, initialTime: _gioDatHen);
                                  if (time != null) setState(() => _gioDatHen = time);
                                },
                                decoration: const InputDecoration(labelText: 'Giờ đặt hẹn *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                                validator: (value) => value!.isEmpty ? 'Trường bắt buộc' : null,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),
                        // Cột 2: Lý do khám và Xác nhận khám
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lý do khám
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Lý do khám', border: OutlineInputBorder()),
                                maxLines: 9, // Tăng kích thước để chiếm không gian
                                onSaved: (value) => _lyDoKham = value ?? '',
                                  validator: (value) =>  value!.isEmpty ? 'Trường bắt buộc' : null
                              ),
                              const SizedBox(height: 10),
                              // Xác nhận khám bệnh (SỬ DỤNG TRẠNG THÁI MỚI)
                              CheckboxListTile(
                                title: const Text('Xác nhận khám bệnh (Bệnh nhân đã đến phòng khám)'),
                                value: _isXacNhanKham, // Dùng biến trạng thái

                                // !!! SỬA LỖI: CHO PHÉP TƯƠNG TÁC BÌNH THƯỜNG
                                onChanged: (v) {
                                  setState(() {
                                    _isXacNhanKham = v!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Nút Hành động
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        ElevatedButton(onPressed: _submitAppointment, child: const Text('Đặt hẹn'),style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),),
                        const SizedBox(width: 10),
                        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy bỏ')),

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