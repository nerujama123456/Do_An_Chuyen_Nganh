// lib/widgets/app_header.dart

import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // Nút thông báo
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 24),
                onPressed: () {
                  // Xử lý thông báo
                },
              ),
              // Vòng tròn thông báo đỏ nhỏ (giả định)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Tên Admin
          const Text(
            'Admin',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(width: 10),

          // Avatar Admin
          const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }
}