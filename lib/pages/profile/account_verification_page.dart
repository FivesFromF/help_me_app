import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class AccountVerificationPage extends StatefulWidget {
  const AccountVerificationPage({super.key});

  @override
  State<AccountVerificationPage> createState() =>
      _AccountVerificationPageState();
}

class _AccountVerificationPageState extends State<AccountVerificationPage> {
  final TextEditingController _cccdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cccdController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final cccd = _cccdController.text.trim();
    if (cccd.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số CCCD')));
      return;
    }

    if (cccd.length != 12) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Số CCCD không hợp lệ')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.updateProfile({'cccdNumber': cccd});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cập nhật CCCD thành công. Hệ thống đang xác thực...',
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUpcomingFeatureDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Tính năng đang được phát triển. Vui lòng thử lại sau!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryBlack,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primaryBlack,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Xác thực tài khoản',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFFDF5ED),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  PhosphorIconsFill.shieldCheck,
                  color: AppColors.primaryOrange,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Xác thực bằng CCCD',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 24),

            // Input Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _cccdController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập số CCCD',
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.identificationCard,
                      color: AppColors.primaryOrange,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.lock,
                  size: 14,
                  color: Color(0xFF999999),
                ),
                SizedBox(width: 8),
                Text(
                  'Thông tin của bạn được bảo mật tuyệt đối',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Xác thực ngay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // VNeID Option Section (Fixed layout)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _showUpcomingFeatureDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              'Tài khoản định danh điện tử',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset(
                            'assets/vneid_logo.png',
                            height: 32,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.security, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // "Hoặc" Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.primaryGreen.withValues(alpha: 0.5),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Hoặc',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.primaryGreen.withValues(alpha: 0.5),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // NFC and QR Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _showUpcomingFeatureDialog,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryGreen,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  PhosphorIconsRegular.rssSimple,
                                  color: AppColors.primaryGreen,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Quét thẻ\nNFC CCCD',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _showUpcomingFeatureDialog,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryGreen,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  PhosphorIconsRegular.qrCode,
                                  color: AppColors.primaryGreen,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Quét QR\nCCCD',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
