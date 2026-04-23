import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/pages/profile/nfc_management_page.dart';
import 'package:help_me_app/pages/profile/qr_management_page.dart';
import 'package:help_me_app/pages/profile/medical_record_page.dart';
import 'package:help_me_app/pages/auth/sign_up/face_enrollment_page.dart';

import 'package:help_me_app/shared/widgets/verification_guard_dialog.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _ensureVerified(BuildContext context, VoidCallback onSuccess) async {
    final profileData = await AuthService.getCachedProfile();
    if (profileData != null && profileData['citizen'] != null) {
      final citizen = CitizenProfile.fromJson(profileData['citizen']);
      if (!citizen.isVerified) {
        if (context.mounted) VerificationGuardDialog.show(context);
        return;
      }
    }
    onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFDF5ED,
      ), // Light cream background from screenshot
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Profile Header
            FutureBuilder<Map<String, dynamic>?>(
              future: AuthService.getCachedProfile(),
              builder: (context, snapshot) {
                final citizen = snapshot.data?['citizen'];
                final fullName = citizen?['fullName'] ?? 'Họ và tên';
                final phone = citizen?['phone'] ?? '(+84) 902044300';
                final isVerified = citizen?['isVerified'] ?? false;

                return Column(
                  children: [
                    // Avatar with Camera Icon
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/placeholder_avatar.png',
                              ), // Placeholder
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Container(
                        //   padding: const EdgeInsets.all(8),
                        //   decoration: const BoxDecoration(
                        //     color: Colors.white,
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: const Icon(
                        //     PhosphorIconsRegular.camera,
                        //     color: AppColors.primaryOrange,
                        //     size: 24,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Verification Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isVerified
                              ? AppColors.primaryGreen
                              : AppColors.primaryOrange,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified
                                ? PhosphorIconsFill.sealCheck
                                : PhosphorIconsRegular.shieldSlash,
                            size: 16,
                            color: isVerified
                                ? AppColors.primaryGreen
                                : AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isVerified ? 'Đã xác thực' : 'Chưa xác thực',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isVerified
                                  ? AppColors.primaryGreen
                                  : AppColors.primaryBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$phone  |  @username',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

            // Account Section
            _buildSection(
              title: 'Về tài khoản của bạn',
              items: [
                _buildSettingItem(
                  icon: PhosphorIconsRegular.userCircleGear,
                  label: 'Thông tin người dùng',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MedicalRecordPage(),
                    ),
                  ),
                ),

                _buildSettingItem(
                  icon: PhosphorIconsRegular.bell,
                  label: 'Thông báo',
                  onTap: () => GoRouter.of(context).go('/notifications'),
                ),
                _buildSettingItem(
                  icon: PhosphorIconsRegular.translate,
                  label: 'Ngôn ngữ',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tiếng Việt',
                        style: TextStyle(
                          color: AppColors.primaryBlack,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Flag placeholder (using Star icon for now as per screenshot)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Device Management Section
            _buildSection(
              title: 'Quản lý định danh',
              items: [
                _buildSettingItem(
                  icon: PhosphorIconsRegular.faceMask,
                  label: 'Cập nhật khuôn mặt',
                  onTap: () => _ensureVerified(context, () => _openFaceEnrollment(context)),
                ),
                _buildSettingItem(
                  icon: PhosphorIconsRegular.rssSimple,
                  label: 'Quản lý thẻ NFC',
                  onTap: () {
                    _ensureVerified(context, () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NfcManagementPage(),
                        ),
                      );
                    });
                  },
                ),
                _buildSettingItem(
                  icon: PhosphorIconsRegular.qrCode,
                  label: 'Quản lý mã QR',
                  onTap: () {
                    _ensureVerified(context, () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const QRManagementPage(),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // App Section
            _buildSection(
              title: 'Về ứng dụng',
              items: [
                _buildSettingItem(
                  icon: PhosphorIconsRegular.playCircle,
                  label: 'Hướng dẫn sử dụng',
                  onTap: () => context.push('/how-to-use'),
                ),
                _buildSettingItem(
                  icon: PhosphorIconsRegular.question,
                  label: 'Hỗ trợ',
                  onTap: () => GoRouter.of(context).go('/support'),
                ),
                _buildSettingItem(
                  icon: PhosphorIconsRegular.fileText,
                  label: 'Chính sách bảo mật',
                  onTap: () => GoRouter.of(context).go('/privacy'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    context.go('/sign-in'); // Redirect to sign-in
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.signOut, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 130),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlack, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(
                      PhosphorIconsRegular.caretRight,
                      color: Colors.grey,
                      size: 24,
                    ),
              ],
            ),
          ),
          // Divider except for last item usually, but for simplicity here we just use it or not
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFEEEEEE),
          ),
        ],
      ),
    );
  }

  void _openFaceEnrollment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FaceEnrollmentPage(
          onFaceCaptured: (path) async {
            // Encode to base64 and update profile
            final bytes = await File(path).readAsBytes();
            final b64 = base64Encode(bytes);

            try {
              await AuthService.updateProfile({'faceImageB64': b64});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật khuôn mặt thành công'),
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
              }
            }
          },
        ),
      ),
    );
  }
}
