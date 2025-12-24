// lib/screens/prescriptions/prescription_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/prescription.dart';
import '../../models/prescription_detail.dart';
import '../../services/prescription_service.dart';
import '../../widgets/sidebar.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  _PrescriptionDetailScreenState createState() => _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Tải cả Header và Detail
    _dataFuture = Future.wait([
      _prescriptionService.getPrescriptionDetails(widget.prescriptionId),
      // Giả định bạn có hàm getPrescriptionHeader(String id) để lấy thông tin header
      // Tạm thời, tôi sẽ gọi fetchPrescriptions và lọc
    ]).then((results) => {
      'details': results[0] as List<PrescriptionDetail>,
      // 'header': results[1] as Prescription, // Nếu có hàm riêng
    });
  }

  // Widget hiển thị bảng chi tiết thuốc
  Widget _buildDetailsTable(List<PrescriptionDetail> details) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('STT')),
        DataColumn(label: Text('Tên thuốc')),
        DataColumn(label: Text('Đơn vị')),
        DataColumn(label: Text('Số lượng')),
        DataColumn(label: Text('Cách dùng')),
        DataColumn(label: Text('Tổng tiền')),
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
          DataCell(Text('${detail.tongtien} VND')),
        ]);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
           Sidebar(currentRoute: '/prescriptions'),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải chi tiết: ${snapshot.error}'));
                }

                final details = snapshot.data!['details'] as List<PrescriptionDetail>;
                // final header = snapshot.data!['header'] as Prescription;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHI TIẾT ĐƠN THUỐC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Divider(),

                      // TODO: Hiển thị thông tin Header đơn thuốc tại đây

                      const SizedBox(height: 20),
                      const Text('Chi tiết các loại thuốc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildDetailsTable(details),
                      ),

                      const SizedBox(height: 30),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại'),
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