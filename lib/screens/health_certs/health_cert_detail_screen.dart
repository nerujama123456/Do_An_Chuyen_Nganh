// lib/screens/health_certs/health_cert_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/health_certification.dart';
import '../../models/prescription_detail.dart'; // Import Model chi tiết thuốc
import '../../services/health_cert_service.dart';
import '../../widgets/sidebar.dart';

class HealthCertDetailScreen extends StatefulWidget {
  final String certId;
  final bool isEditing;

  const HealthCertDetailScreen({super.key, required this.certId, this.isEditing = false});

  @override
  _HealthCertDetailScreenState createState() => _HealthCertDetailScreenState();
}

class _HealthCertDetailScreenState extends State<HealthCertDetailScreen> {
  final HealthCertService _healthCertService = HealthCertService();

  // Kiểu Future để chứa tất cả dữ liệu cần thiết
  late Future<Map<String, dynamic>> _dataFuture;

  final _formKey = GlobalKey<FormState>();

  // Tên biến Dart đã chuẩn hóa chữ thường
  String _ketluan = '';
  String _huongdandieutri = '';
  String _denghikhamlamsang = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final certFuture = _healthCertService.getHealthCertification(widget.certId);

    // Sử dụng FutureBuilder để tải tất cả dữ liệu
    _dataFuture = certFuture.then((cert) {
      if (cert.prescription_id != null) {
        // Chỉ tải đơn thuốc nếu prescription_id tồn tại
        final headerFuture = _healthCertService.getPrescriptionHeaderByPrescriptionId(cert.prescription_id!);
        final detailsFuture = _healthCertService.getPrescriptionDetailsByPrescriptionId(cert.prescription_id!);

        return Future.wait([headerFuture, detailsFuture]).then((prescriptionResults) {
          return {
            'cert': cert,
            'prescription': prescriptionResults[0], // Header
            'details': prescriptionResults[1], // Chi tiết
          };
        });
      }
      // Trả về null nếu không có đơn thuốc liên quan
      return {'cert': cert, 'prescription': null, 'details': <PrescriptionDetail>[]};
    });

    setState(() {}); // Cập nhật state để FutureBuilder chạy
  }


  void _submitConclusion(HealthCertification cert) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final data = {
        'ketluan': _ketluan,
        'huongdandieutri': _huongdandieutri,
        'denghikhamlamsang': _denghikhamlamsang,
        'trangthai': 'Đã khám',
      };

      final success = await _healthCertService.updateHealthCertConclusion(cert.id, data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật kết luận thành công!')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại.'), backgroundColor: Colors.redAccent));
        }
      }
    }
  }

  // Widget hiển thị bảng chi tiết thuốc (SỬ DỤNG TRONG PHẦN BUILD)
  Widget _buildDetailsTable(List<PrescriptionDetail> details) {
    return DataTable(
      columnSpacing: 15,
      columns: const [
        DataColumn(label: Text('STT')),
        DataColumn(label: Text('Tên thuốc')),
        DataColumn(label: Text('Đơn vị')),
        DataColumn(label: Text('Số lượng')),
        DataColumn(label: Text('Cách dùng')),
        DataColumn(label: Text('Giá (VND)')),
        DataColumn(label: Text('Tổng tiền (VND)')),
      ],
      rows: details.asMap().entries.map((entry) {
        final index = entry.key;
        final detail = entry.value;
        return DataRow(cells: [
          DataCell(Text((index + 1).toString())),
          DataCell(Text(detail.tenthuoc)),
          DataCell(Text(detail.donvitinh)),
          DataCell(Text(detail.soluong.toString())),
          DataCell(Text(detail.cachdung)),
          DataCell(Text(detail.giavnd.toString())),
          DataCell(Text(detail.tongtien.toString())),
        ]);
      }).toList(),
    );
  }


  Widget _buildInfoField(String label, String value, [bool isBold = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.grey[700]))),
          Expanded(flex: 7, child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildReadOnlyOrEditableField({
    required String labelText,
    String? initialValue,
    required bool isEditable,
    bool isMultiline = false,
    required FormFieldSetter<String> onSaved,
  }) {
    if (isEditable) {
      return TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        maxLines: isMultiline ? 5 : 1,
        onSaved: onSaved,
        validator: (value) => labelText.contains('*') && (value == null || value.isEmpty) ? 'Vui lòng điền thông tin' : null,
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labelText.replaceAll('*', ''), style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 5),
          Text(initialValue ?? '---', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String route = widget.isEditing ? 'Kết luận giấy khám bệnh' : 'Thông tin giấy khám bệnh';

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/health_certs'),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}.'));
                }

                final cert = snapshot.data!['cert'] as HealthCertification;
                final prescriptionHeader = snapshot.data!['prescription'] as Map<String, dynamic>?;
                final prescriptionDetails = snapshot.data!['details'] as List<PrescriptionDetail>;


                if (widget.isEditing) {
                  _ketluan = cert.ketluan ?? '';
                  _huongdandieutri = cert.huongdandieutri ?? '';
                  _denghikhamlamsang = cert.denghikhamlamsang ?? '';
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(route.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Divider(),

                      // KHỐI THÔNG TIN KHÁM
                      Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thông tin khám', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              _buildInfoField('Mã giấy khám bệnh:', cert.ma),
                              _buildInfoField('Tiêu đề:', cert.title),
                              _buildInfoField('Tên bệnh nhân:', cert.tenbenhnhan),
                              _buildInfoField('Phòng khám:', cert.phongkham),
                              _buildInfoField('Bác sĩ:', cert.bacsi),
                              _buildInfoField('Trạng thái:', cert.trangthai),
                              _buildInfoField('Thanh toán:', cert.thanhtoan),
                              _buildInfoField('Giá:', '${cert.gia} VND'),
                            ],
                          ),
                        ),
                      ),

                      // KHỐI KẾT QUẢ KHÁM & ĐƠN THUỐC
                      Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kết quả khám', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),

                                // Kết Luận
                                _buildReadOnlyOrEditableField(
                                  labelText: 'Kết luận *',
                                  initialValue: cert.ketluan,
                                  isEditable: widget.isEditing,
                                  onSaved: (value) => _ketluan = value ?? '',
                                ),
                                const SizedBox(height: 15),

                                // Hướng dẫn điều trị
                                _buildReadOnlyOrEditableField(
                                  labelText: 'Hướng dẫn điều trị *',
                                  initialValue: cert.huongdandieutri,
                                  isEditable: widget.isEditing,
                                  onSaved: (value) => _huongdandieutri = value ?? '',
                                ),
                                const SizedBox(height: 15),

                                // Đề nghị khám lâm sàng
                                _buildReadOnlyOrEditableField(
                                  labelText: 'Đề nghị khám lâm sàng',
                                  initialValue: cert.denghikhamlamsang,
                                  isEditable: widget.isEditing,
                                  isMultiline: true,
                                  onSaved: (value) => _denghikhamlamsang = value ?? '',
                                ),

                                // --- HIỂN THỊ ĐƠN THUỐC (Chỉ khi có liên kết và Đã khám) ---
                                if (cert.prescription_id != null && cert.trangthai == 'Đã khám') ...[
                                  const SizedBox(height: 30),
                                  const Text('Đơn thuốc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Divider(),

                                  // Thông tin Header Đơn thuốc
                                  _buildInfoField('Mã đơn thuốc:', prescriptionHeader?['ma'] ?? 'N/A'),
                                  _buildInfoField('Tổng tiền:', '${prescriptionHeader?['tongtien'] ?? 0} VND'),
                                  _buildInfoField('Trạng thái:', prescriptionHeader?['trangthai'] ?? 'N/A'),

                                  const SizedBox(height: 15),
                                  const Text('Chi tiết đơn thuốc:', style: TextStyle(fontWeight: FontWeight.bold)),

                                  // Bảng chi tiết thuốc
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: _buildDetailsTable(prescriptionDetails),
                                  ),
                                ],
                                // --- END HIỂN THỊ ĐƠN THUỐC ---

                                const SizedBox(height: 30),

                                // Nút Hành động
                                Row(
                                  children: [
                                    if (widget.isEditing)
                                      ElevatedButton(
                                        onPressed: () => _submitConclusion(cert),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}