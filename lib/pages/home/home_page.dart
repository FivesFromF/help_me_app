import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

import 'package:help_me_app/pages/identity_verification/face_recognition_page.dart';
import 'package:help_me_app/pages/identity_verification/identity_scan_page.dart';
import 'package:help_me_app/pages/identity_verification/qr_scanner_page.dart';
import 'package:help_me_app/pages/history/history_page.dart';
import 'package:help_me_app/pages/settings/settings_page.dart';
import 'package:help_me_app/shared/widgets/verification_guard_dialog.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';
import 'package:help_me_app/shared/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  List<Widget> get _pages => const [
    HomeDashboard(),
    HomeDashboard(),
    HistoryPage(),
    SettingsPage(),
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
    final int safeIndex = _selectedIndex >= _pages.length ? 0 : _selectedIndex;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _pages[safeIndex],
          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: _CustomFloatingNavBar(
              selectedIndex: safeIndex,
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
            child: _buildNavItem(3, PhosphorIconsRegular.gear, 'Cài đặt'),
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
    final citizen = profile != null ? (profile['citizen'] ?? profile['profile']) : null;
    if (citizen != null) {
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

                // Emergency Call Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
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
                          onTap: () async {
                            final uri = Uri.parse('tel:115');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
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
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang kết nối Video Call tới Tổng đài hỗ trợ 115...'),
                                backgroundColor: AppColors.primaryOrange,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Incident Report Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStandaloneEmergencySheet(context),
                    icon: const Icon(PhosphorIconsFill.siren, size: 24),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Báo cáo khẩn cấp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
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

  void _showStandaloneEmergencySheet(BuildContext context) {
    final TextEditingController descController = TextEditingController(
      text: 'Cần hỗ trợ cứu hộ khẩn cấp tại hiện trường.',
    );
    String selectedTag = 'Tai nạn giao thông';
    bool isSubmitting = false;

    LocationResult? currentLocation;
    bool isLocating = true;

    final List<String> quickTags = [
      'Tai nạn giao thông',
      'Bất tỉnh / Ngất xỉu',
      'Chấn thương nặng',
      'Khó thở / Co giật',
      'Đột quỵ / Đau tim',
      'Hỏa hoạn / Cháy nổ',
      'Khác',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLocating && currentLocation == null) {
            LocationService.getCurrentLocation().then((loc) {
              if (context.mounted) {
                setSheetState(() {
                  currentLocation = loc;
                  isLocating = false;
                });
              }
            });
          }

          final String latStr = currentLocation?.latString ?? LocationService.defaultLat.toString();
          final String lonStr = currentLocation?.lonString ?? LocationService.defaultLon.toString();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Top Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        PhosphorIconsFill.siren,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Báo cáo sự cố khẩn cấp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: isSubmitting ? null : () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),

                // Sheet Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GPS Location Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isLocating
                                ? const Color(0xFFF0F9FF)
                                : (currentLocation?.isRealGps == true
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFFFFBEB)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isLocating
                                  ? const Color(0xFFBAE6FD)
                                  : (currentLocation?.isRealGps == true
                                      ? const Color(0xFFBBF7D0)
                                      : const Color(0xFFFDE68A)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsFill.mapPin,
                                color: isLocating
                                    ? const Color(0xFF0284C7)
                                    : (currentLocation?.isRealGps == true
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFD97706)),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isLocating
                                                ? 'Đang lấy vị trí GPS thực tế...'
                                                : (currentLocation?.isRealGps == true
                                                    ? 'Vị trí GPS thời gian thực'
                                                    : 'Vị trí dự phòng (GPS tắt)'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: isLocating
                                                  ? const Color(0xFF0369A1)
                                                  : (currentLocation?.isRealGps == true
                                                      ? const Color(0xFF15803D)
                                                      : const Color(0xFFB45309)),
                                            ),
                                          ),
                                        ),
                                        if (currentLocation?.isRealGps == true && currentLocation?.accuracy != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '±${currentLocation!.accuracy!.toStringAsFixed(1)}m',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isLocating
                                          ? 'Đang đồng bộ với vệ tinh định vị...'
                                          : 'Tọa độ: $latStr, $lonStr',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isLocating)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0284C7),
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: 'Làm mới vị trí GPS',
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    color: Color(0xFF0284C7),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setSheetState(() {
                                      isLocating = true;
                                    });
                                    LocationService.getCurrentLocation().then((loc) {
                                      if (context.mounted) {
                                        setSheetState(() {
                                          currentLocation = loc;
                                          isLocating = false;
                                        });
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quick Situation Selector
                        const Text(
                          'Tình trạng sự cố khẩn cấp',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: quickTags.map((tag) {
                            final isSelected = selectedTag == tag;
                            return ChoiceChip(
                              label: Text(tag),
                              selected: isSelected,
                              selectedColor: const Color(0xFFDC2626),
                              backgroundColor: const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFFDC2626) : Colors.transparent,
                                ),
                              ),
                              onSelected: isSubmitting
                                  ? null
                                  : (selected) {
                                      if (selected) {
                                        setSheetState(() {
                                          selectedTag = tag;
                                          descController.text =
                                              '[$tag] Cần cứu hộ y tế / hỗ trợ khẩn cấp tại hiện trường.';
                                        });
                                      }
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Situation Details Input
                        const Text(
                          'Mô tả chi tiết hiện trường',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descController,
                          maxLines: 3,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            hintText: 'Nhập thông tin mô tả chi tiết vị trí, hiện trường...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setSheetState(() => isSubmitting = true);
                                    try {
                                      final result = await AuthService.reportEmergency(
                                        locationLat: latStr,
                                        locationLon: lonStr,
                                        situationDescription: descController.text.trim(),
                                      );

                                      if (context.mounted) {
                                        Navigator.of(sheetContext).pop();
                                        _showEmergencySuccessDialog(context, result);
                                      }
                                    } catch (e) {
                                      setSheetState(() => isSubmitting = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi gửi báo cáo: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(PhosphorIconsFill.paperPlaneTilt, size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'XÁC NHẬN GỬI CỨU HỘ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEmergencySuccessDialog(BuildContext context, Map<String, dynamic> result) {
    final String reportId = (result['reportId'] ?? result['id'] ?? 'N/A').toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yêu cầu cứu hộ đã gửi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tín hiệu khẩn cấp kèm định vị GPS đã được chuyển tiếp đến Trung tâm điều phối cấp cứu 115 và lực lượng hỗ trợ.',
              style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text(
                    'Mã sự cố: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      '#${reportId.length > 8 ? reportId.substring(0, 8).toUpperCase() : reportId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xác nhận'),
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

  Widget _buildBottomAction(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
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
        ),
      ),
    );
  }
}
