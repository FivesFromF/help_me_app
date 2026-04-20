import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String _content = '';

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    // Try to load a local markdown or text file if present; fallback to short summary
    try {
      final text = await rootBundle.loadString('assets/privacy.txt');
      setState(() => _content = text);
    } catch (_) {
      setState(() => _content =
          'HelpMe cam kết bảo vệ dữ liệu cá nhân. Vui lòng liên hệ privacy@helpme.vn để biết chi tiết.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Chính sách bảo mật', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(_content),
        ),
      ),
    );
  }
}
