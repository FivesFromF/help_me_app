import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                final profile = snapshot.data;
                final fullName = profile?['fullName'] ?? 'Họ và tên';
                final phone = profile?['phone'] ?? '(+84) 902044300';

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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.camera,
                            color: AppColors.primaryOrange,
                            size: 24,
                          ),
                        ),
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
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsFill.shieldSlash,
                            size: 16,
                            color: AppColors.primaryOrange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Chưa xác thực',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlack,
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
                  onTap: () {},
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

            // App Section
            _buildSection(
              title: 'Về ứng dụng',
              items: [
                _buildSettingItem(
                  icon: PhosphorIconsRegular.playCircle,
                  label: 'Hướng dẫn sử dụng',
                  onTap: () {},
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
}
