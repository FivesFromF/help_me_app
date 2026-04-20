import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Thông báo', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: SwitchListTile(
                title: const Text('Cảnh báo truy xuất hồ sơ'),
                value: true,
                onChanged: (v) {},
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Cảnh báo thiết bị liên kết'),
                value: true,
                onChanged: (v) {},
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Tin tức & Tính năng mới'),
                value: true,
                onChanged: (v) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
