import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

import 'package:help_me_app/pages/identity_verification/face_recognition_page.dart';
import 'package:help_me_app/pages/identity_verification/identity_scan_page.dart';
import 'package:help_me_app/pages/identity_verification/qr_scanner_page.dart';
import 'package:help_me_app/pages/settings/settings_page.dart';
import 'package:help_me_app/shared/widgets/verification_guard_dialog.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const HomeDashboard(),
    const Center(child: Text('Lịch sử')),
    const Center(child: Text('Tin tức')),
    const SettingsPage(),
  ];

  Future<void> _onNavItemSelected(int index) async {
    if (index == 1) {
      // Check verification status before entering Profile
      final profileData = await AuthService.getCachedProfile();
      if (profileData != null && profileData['citizen'] != null) {
        final citizen = CitizenProfile.fromJson(profileData['citizen']);
        if (!citizen.isVerified) {
          if (mounted) VerificationGuardDialog.show(context);
          return;
        }
      }
      if (mounted) context.push('/profile');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: _CustomFloatingNavBar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onNavItemSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const _CustomFloatingNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildNavItem(0, PhosphorIconsFill.house, 'Trang chủ'),
          ),
          Expanded(
            child: _buildNavItem(1, PhosphorIconsRegular.userCircle, 'Hồ sơ'),
          ),
          Expanded(
            child: _buildNavItem(
              2,
              PhosphorIconsRegular.clockCounterClockwise,
              'Lịch sử',
            ),
          ),
          Expanded(
            child: _buildNavItem(3, PhosphorIconsRegular.article, 'Tin tức'),
          ),
          Expanded(
            child: _buildNavItem(4, PhosphorIconsRegular.gear, 'Cài đặt'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDEEE0) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryOrange
                  : const Color(0xFF555555),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryOrange
                    : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String _displayName = '...';
  bool _isVerified = false;
  bool _isProfileUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getCachedProfile();
    if (profile != null && profile['citizen'] != null) {
      final citizen = profile['citizen'];
      
      // Safety check: if flags are false, kick back to splash to decide where to go
      final bool firstDeclare = citizen['firstDeclareProfile'] ?? citizen['first_declare_profile'] ?? false;
      final bool consent = citizen['consentRegulation'] ?? citizen['consent_regulation'] ?? false;
      
      if (!firstDeclare || !consent) {
        if (mounted) context.go('/');
        return;
      }

      setState(() {
        _displayName = (citizen['fullName'] ?? 'Người dùng').toUpperCase();
        _isVerified = citizen['isVerified'] ?? false;
        _isProfileUpdated = citizen['isProfileUpdated'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Orange Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0), // No curve in screenshot
                bottomRight: Radius.circular(0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                              children: [
                                const TextSpan(text: 'Chào '),
                                TextSpan(
                                  text: _displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatusChip(
                                _isVerified
                                    ? PhosphorIconsFill.shieldCheck
                                    : PhosphorIconsRegular.shieldSlash,
                                _isVerified ? 'Đã xác thực' : 'Chưa xác thực',
                                isPositive: _isVerified,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(
                                _isProfileUpdated
                                    ? PhosphorIconsFill.folderSimple
                                    : PhosphorIconsRegular.folderSimple,
                                _isProfileUpdated
                                    ? 'Đã cập nhật hồ sơ'
                                    : 'Chưa cập nhật hồ sơ',
                                isPositive: _isProfileUpdated,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Stack(
                        children: [
                          Icon(
                            PhosphorIconsRegular.bell,
                            color: Colors.white,
                            size: 28,
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Khi bạn thấy người gặp nạn,\nngười bị té ngã hoặc bất tỉnh?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),

                // FACE RECOGNITION CARD
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FaceRecognitionPage(),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip
                        .none, // Quan trọng: Để con cái có thể bay ra ngoài viền
                    children: [
                      // BƯỚC 1: Đưa cái Card màu cam nhạt vào làm con của Stack
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF0E3), // Peach background
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Nhận diện',
                                    style: TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'khuôn mặt',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryBlack,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Circle Button (Phần icon cam đậm)
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    PhosphorIconsRegular.userFocus,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // BƯỚC 2: Cái Decorative Shape bây giờ nằm đè lên Card và có thể văng ra ngoài
                      Positioned(
                        top: -15,
                        right: 40,
                        child: Container(
                          width: 80,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // NFC and QR Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Thẻ NFC',
                        'Quét thẻ',
                        const Icon(
                          PhosphorIconsFill.rssSimple,
                          color: Colors.white,
                          size: 48,
                        ),
                        AppColors.primaryGreen,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const IdentityScanPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        'Mã QR',
                        'Quét QR',
                        const Icon(
                          PhosphorIconsFill.qrCode,
                          color: Colors.white,
                          size: 48,
                        ),
                        AppColors.primaryGreen,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QRScannerPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Emergency Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBottomAction(
                          PhosphorIconsRegular.phoneCall,
                          'Gọi 115',
                          AppColors.primaryGreen,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: const Color(0xFFF0F0F0),
                      ),
                      Expanded(
                        child: _buildBottomAction(
                          PhosphorIconsRegular.videoCamera,
                          'Video call trực tiếp',
                          AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120), // Placeholder for floating nav bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    IconData icon,
    String label, {
    bool isPositive = false,
  }) {
    final color = isPositive ? AppColors.primaryGreen : AppColors.primaryOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    Widget icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 15),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlack,
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: icon),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlack,
          ),
        ),
      ],
    );
  }
}
