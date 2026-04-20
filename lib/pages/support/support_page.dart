import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Hỗ trợ', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ illustration from assets
            Center(
              child: Image.asset(
                'assets/FAQ.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Câu hỏi thường gặp (FAQ)',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Xem các câu hỏi thường gặp hoặc liên hệ hotline / email để được hỗ trợ nhanh.',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Hotline'),
                subtitle: const Text('Thứ 2 đến Thứ 6 | 8 giờ đến 17 giờ'),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email hỗ trợ'),
                subtitle: const Text('privacy@helpme.vn'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
