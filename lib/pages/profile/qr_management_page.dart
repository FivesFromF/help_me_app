import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRManagementPage extends StatefulWidget {
  const QRManagementPage({super.key});

  @override
  State<QRManagementPage> createState() => _QRManagementPageState();
}

class _QRManagementPageState extends State<QRManagementPage> {
  List<dynamic> _qrcodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQRCodes();
  }

  Future<void> _loadQRCodes() async {
    setState(() => _isLoading = true);
    try {
      final codes = await AuthService.getQRCodes();
      setState(() {
        _qrcodes = codes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách mã QR: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewQRCode() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo mã QR mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên gợi nhớ (VD: QR cá nhân)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            child: const Text('Tạo ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await AuthService.createQRCode(result);
        _loadQRCodes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tạo mã QR: $e')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5ED),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          'Quản lý mã QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : _qrcodes.isEmpty
              ? _buildEmptyState()
              : _buildQRList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewQRCode,
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
        label: const Text(
          'Tạo mã mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.qrCode,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'Bạn chưa có mã QR nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tạo mã QR để người cứu hộ có thể nhanh chóng định danh bạn qua Camera.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _qrcodes.length,
      itemBuilder: (context, index) {
        final code = _qrcodes[index];
        final isActive = code['status'] == 'ACTIVE';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showQRCodeDialog(code),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.primaryOrange : Colors.grey)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsFill.qrCode,
                    color: isActive ? AppColors.primaryOrange : Colors.grey,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code['name'] ?? 'Mã QR của tôi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${code['id']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primaryGreen : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Đang hoạt động' : 'Tạm khóa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.primaryGreen : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(value, code),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('Xem mã QR'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(isActive ? 'Tạm khóa' : 'Kích hoạt lại'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa mã', style: TextStyle(color: Colors.red)),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQRCodeDialog(dynamic code) {
    // QR Content is JSON as per requirements: { "qrId": "...", "hash": "..." }
    final String qrContent = jsonEncode({
      'qrId': code['id'],
      'hash': code['hashedCitizenId'],
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code['name'] ?? 'Mã QR',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: qrContent,
                  version: QrVersions.auto,
                  size: 240,
                  gapless: false,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đưa mã này cho người cứu hộ để họ có thể trợ giúp bạn nhanh nhất.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Đóng', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(String action, dynamic code) async {
    try {
      if (action == 'view') {
        _showQRCodeDialog(code);
      } else if (action == 'toggle') {
        final newStatus = code['status'] == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
        await AuthService.updateQRCodeStatus(code['id'], newStatus);
        _loadQRCodes();
      } else if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa mã QR này? Người cứu hộ sẽ không thể sử dụng mã này nữa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        await AuthService.deleteQRCode(code['id']);
        _loadQRCodes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
