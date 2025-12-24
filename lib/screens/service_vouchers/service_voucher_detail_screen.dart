// lib/screens/service_vouchers/service_voucher_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/service_voucher.dart';
import '../../services/service_voucher_service.dart';
import '../../widgets/sidebar.dart';

class ServiceVoucherDetailScreen extends StatefulWidget {
  final String voucherId;

  const ServiceVoucherDetailScreen({super.key, required this.voucherId});

  @override
  _ServiceVoucherDetailScreenState createState() => _ServiceVoucherDetailScreenState();
}

class _ServiceVoucherDetailScreenState extends State<ServiceVoucherDetailScreen> {
  final ServiceVoucherService _voucherService = ServiceVoucherService();
  late Future<ServiceVoucher> _voucherFuture;

  @override
  void initState() {
    super.initState();
    _voucherFuture = _voucherService.getServiceVoucherDetail(widget.voucherId);
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

  @override
  Widget build(BuildContext context) {
    const String route = 'Thông tin phiếu dịch vụ';

    return Scaffold(
      body: Row(
        children: <Widget>[
           Sidebar(currentRoute: '/service_vouchers'),
          Expanded(
            child: FutureBuilder<ServiceVoucher>(
              future: _voucherFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}.'));
                }

                final voucher = snapshot.data!;
                final String isPaid = voucher.thanhtoan == 'Đã thanh toán' ? 'Đã' : 'Chưa';
                final String isExamined = voucher.trangthai == 'Đã khám xong' ? 'Đã' : 'Chưa';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quản lý phiếu dịch vụ / $route', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 10),
                      Text(route.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Divider(),

                      // KHỐI THÔNG TIN DỊCH VỤ
                      Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thông tin phiếu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              _buildInfoField('Mã phiếu:', voucher.ma),
                              _buildInfoField('Tên bệnh nhân:', voucher.tenbenhnhan, true),
                              _buildInfoField('Bác sĩ:', voucher.bacsi),
                              _buildInfoField('Dịch vụ:', voucher.dichvukham),
                              _buildInfoField('Ngày bắt đầu:', voucher.ngaybatdau),
                              _buildInfoField('Ngày kết thúc:', voucher.ngayketthuc),
                              _buildInfoField('Trạng thái khám:', isExamined),
                              _buildInfoField('Thanh toán:', isPaid),
                              _buildInfoField('Tổng tiền:', '${voucher.tongtien} VND'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
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