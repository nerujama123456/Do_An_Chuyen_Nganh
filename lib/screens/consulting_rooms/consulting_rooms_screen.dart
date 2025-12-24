// lib/screens/consulting_rooms/consulting_rooms_screen.dart

import 'package:flutter/material.dart';
import '../../models/consulting_room.dart';
import '../../services/data_service.dart';
import '../../widgets/sidebar.dart';
import 'consulting_room_edit_screen.dart';
import 'consulting_room_form_screen.dart';

class ConsultingRoomsScreen extends StatefulWidget {
  @override
  _ConsultingRoomsScreenState createState() => _ConsultingRoomsScreenState();
}

class _ConsultingRoomsScreenState extends State<ConsultingRoomsScreen> {
  // !!! KHỞI TẠO LATE FUTURE (Đã sửa)
  late Future<List<ConsultingRoom>> _roomsFuture;
  final DataService _dataService = DataService();

  // Định nghĩa chiều rộng cố định cho các cột
  final Map<String, double> _columnWidths = const {
    'STT': 100.0,
    'Ma': 400.0,
    'TenPhongKham': 400.0,
    'HoatDong': 350.0,
  };

  final TextEditingController _searchController = TextEditingController();
  List<ConsultingRoom> _allRooms = []; // Danh sách gốc
  String _searchQuery = ''; // Từ khóa tìm kiếm

  @override
  void initState() {
    super.initState();
    // Gán Future mặc định
    _roomsFuture = Future.value([]);
    _loadData();
  }

  void _loadData() async {
    try {
      final maps = await _dataService.fetchConsultingRooms();
      final rooms = maps.map((map) => ConsultingRoom.fromJson(map)).toList();

      if (mounted) {
        setState(() {
          _allRooms = rooms;
          _roomsFuture = Future.value(_filterRooms(_allRooms, _searchQuery));
        });
      }
    } catch (e) {
      if (mounted) {
        _roomsFuture = Future.error(e);
        setState(() {});
      }
    }
  }

  // HÀM LỌC DỮ LIỆU CỤC BỘ
  List<ConsultingRoom> _filterRooms(List<ConsultingRoom> rooms, String query) {
    if (query.isEmpty) {
      return rooms;
    }
    final lowerCaseQuery = query.toLowerCase();

    return rooms.where((room) {
      final indexString = (rooms.indexOf(room) + 1).toString();

      return indexString.contains(lowerCaseQuery) ||
          room.ma.toLowerCase().contains(lowerCaseQuery) ||
          room.tenphongkham.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _roomsFuture = Future.value(_filterRooms(_allRooms, _searchQuery));
    });
  }


  void _deleteRoom(int roomId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phòng khám này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _dataService.deleteCatalogItem('consulting_rooms', roomId);
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa phòng khám thành công!'), backgroundColor: Colors.green));
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại. Phòng khám đang được sử dụng.'), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  // --- WIDGET CỐ ĐỊNH: HEADER BẢNG ---
  Widget _buildFixedTableHeader() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border(bottom: BorderSide(color: Colors.grey.shade400))),

      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), // Tăng padding
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: const Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['Ma'], child: const Text('Mã', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['TenPhongKham'], child: const Text('Tên phòng khám', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: _columnWidths['HoatDong'], child: const Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HÀNG DỮ LIỆU CUỘN ---
  Widget _buildDataRow(ConsultingRoom room, int index) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: <Widget>[
            SizedBox(width: _columnWidths['STT'], child: Text((index + 1).toString())),
            SizedBox(width: _columnWidths['Ma'], child: Text(room.ma)),
            SizedBox(width: _columnWidths['TenPhongKham'], child: Text(room.tenphongkham)),
            SizedBox(width: _columnWidths['HoatDong'], child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ConsultingRoomEditScreen(roomId: room.id, onSave: _loadData),
                    ));
                    _loadData();
                  },
                  tooltip: 'Chỉnh sửa'
              ),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteRoom(room.id), tooltip: 'Xóa'),
            ])),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const String currentRoute = '/consulting_rooms';

    return Scaffold(
      body: Row(
        children: <Widget>[
          Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('DANH SÁCH PHÒNG KHÁM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(),

                  // THANH TÌM KIẾM
                  Row(
                    children: [
                      SizedBox(
                          width: 300,
                          child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Nhập tên hoặc mã phòng khám',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              )
                          )
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _performSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('Tìm kiếm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),
                      ),
                      const Spacer(),

                      // Nút Thêm phòng khám
                      ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ConsultingRoomFormScreen(onSave: _loadData),
                            ));
                            _loadData();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm phòng khám'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white)
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // HEADER BẢNG CỐ ĐỊNH
                  _buildFixedTableHeader(),

                  // Bảng dữ liệu CUỘN DỌC
                  Expanded(
                    child: FutureBuilder<List<ConsultingRoom>>(
                      future: _roomsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                        if (snapshot.hasData) {
                          // ListView.separated để cuộn dọc và thêm đường kẻ
                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return _buildDataRow(snapshot.data![index], index);
                            },
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                          );
                        }
                        return const Center(child: Text('Không có phòng khám nào.'));
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}