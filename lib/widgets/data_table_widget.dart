// lib/widgets/data_table_widget.dart

import 'package:flutter/material.dart';

class CustomDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? headerActions; // Ví dụ: Nút Thêm mới

  const CustomDataTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.headerActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Phần Header (Tìm kiếm và Hành động)
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                // Khung tìm kiếm giả định
                const SizedBox(
                  width: 250,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Tìm kiếm'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                ),
                const Spacer(),
                if (headerActions != null) headerActions!,
              ],
            ),
          ),

          const Divider(height: 1),

          // Bảng dữ liệu
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 30,
              dataRowMaxHeight: 60,
              headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey[100]),
              columns: columns,
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}