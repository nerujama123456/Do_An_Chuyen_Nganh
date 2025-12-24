// lib/models/consulting_room.dart

class ConsultingRoom {
  final int id;
  final String ma;
  final String tenphongkham;

  ConsultingRoom({
    required this.id,
    required this.ma,
    required this.tenphongkham,
  });

  factory ConsultingRoom.fromJson(Map<String, dynamic> json) {
    return ConsultingRoom(
      id: json['id'] as int,
      ma: json['ma'] ?? '',
      tenphongkham: json['tenphongkham'] ?? '',
    );
  }
}