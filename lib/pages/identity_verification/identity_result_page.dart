import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/shared/services/location_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class IdentityResultPage extends StatefulWidget {
  final Map<dynamic, dynamic> data;

  const IdentityResultPage({super.key, required this.data});

  @override
  State<IdentityResultPage> createState() => _IdentityResultPageState();
}

class _IdentityResultPageState extends State<IdentityResultPage> {
  int _selectedCandidateIndex = 0;

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootData = _toMap(widget.data);

    // Extract candidates if face scanning returned multiple matches (1-3)
    final dynamic rawMatches = rootData['topMatches'];
    final List<Map<String, dynamic>> candidateList = [];
    if (rawMatches is List && rawMatches.isNotEmpty) {
      for (final item in rawMatches) {
        if (item is Map) {
          candidateList.add(_toMap(item));
        }
      }
    }

    // Determine active profile & medical record based on selected candidate
    Map<String, dynamic> profile;
    Map<String, dynamic> medical;
    if (candidateList.isNotEmpty &&
        _selectedCandidateIndex < candidateList.length) {
      final activeCandidate = candidateList[_selectedCandidateIndex];
      profile = _toMap(
        activeCandidate['victim'] ??
            activeCandidate['citizen'] ??
            activeCandidate,
      );
      medical = _toMap(
        activeCandidate['record'] ??
            activeCandidate['medicalRecord'] ??
            profile['medicalRecord'] ??
            rootData['record'],
      );
    } else {
      profile = _toMap(
        rootData['citizen'] ?? rootData['victim'] ?? rootData['profile'],
      );
      medical = _toMap(
        rootData['record'] ??
            rootData['medicalRecord'] ??
            profile['medicalRecord'],
      );
    }

    final dynamic rawContacts = profile['emergencyContacts'] ??
        profile['emergency_contacts'] ??
        rootData['emergencyContacts'] ??
        rootData['contacts'];
    final List<dynamic> contacts = rawContacts is List ? rawContacts : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thông tin cứu hộ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // Warning Box at the top
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFA39E)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          PhosphorIconsFill.warningCircle,
                          color: Color(0xFFF5222D),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CẢNH BÁO QUAN TRỌNG',
                                style: TextStyle(
                                  color: Color(0xFFF5222D),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 8,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Bạn đang truy cập thông tin cá nhân của công dân. Mọi hành vi trục lợi, sử dụng dữ liệu với mục đích không phục vụ cho nhu cầu y tế khẩn cấp đều trái với quy định Pháp luật và sẽ bị xử lý nghiêm minh!',
                                style: TextStyle(
                                  color: Color(0xFFF5222D),
                                  fontSize: 8,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Multi-candidate selector banner if > 1 matches
                  if (candidateList.length > 1) ...[
                    _buildCandidateSelector(candidateList),
                    const SizedBox(height: 16),
                  ],

                  // Identity Card (Medical Record Style)
                  _buildIdentityCard(profile),
                  const SizedBox(height: 16),

                  // Medical Info Card (Medical Record Style)
                  _buildMedicalInfoCard(medical),
                ],
              ),
            ),
          ),
          // Action Buttons Section
          _buildActionSection(context, profile, medical, contacts),
        ],
      ),
    );
  }

  Widget _buildCandidateSelector(List<Map<String, dynamic>> candidateList) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsFill.usersThree,
                color: Color(0xFF16A34A),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tìm thấy ${candidateList.length} người có khuôn mặt tương đồng',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Nhấn vào từng ứng viên để đối chiếu và xem hồ sơ y tế tương ứng:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF166534),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: candidateList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final cand = candidateList[idx];
                final candVictim = _toMap(cand['victim'] ?? cand['citizen'] ?? cand);
                final String candName = candVictim['fullName'] ?? 'Ứng viên #${idx + 1}';
                final String? candAvatar = candVictim['avatarUrl'] ?? candVictim['avatar_url'];
                final double distance = double.tryParse(cand['distance']?.toString() ?? '') ?? 0.2;
                final int matchPercent = ((1.0 - (distance / 0.35)) * 100).clamp(50, 99).round();
                final bool isSelected = _selectedCandidateIndex == idx;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCandidateIndex = idx;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFBBF7D0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Avatar Thumbnail
                        Container(
                          width: 44,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: candAvatar != null &&
                                  candAvatar.isNotEmpty &&
                                  (candAvatar.startsWith('http://') ||
                                      candAvatar.startsWith('https://'))
                              ? Image.network(
                                  candAvatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    PhosphorIconsRegular.userCircle,
                                    size: 28,
                                    color: Color(0xFF94A3B8),
                                  ),
                                )
                              : const Icon(
                                  PhosphorIconsRegular.userCircle,
                                  size: 28,
                                  color: Color(0xFF94A3B8),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                candName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF86EFAC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$matchPercent% khớp',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF14532D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(Map<String, dynamic> profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              (profile['fullName'] ?? 'Người dùng').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: () {
                    final String? avatarUrl = (profile['avatarUrl'] ??
                            profile['avatar_url'] ??
                            profile['avatar'] ??
                            profile['photoUrl'] ??
                            profile['picture'])
                        ?.toString()
                        .trim();

                    if (avatarUrl != null &&
                        avatarUrl.isNotEmpty &&
                        (avatarUrl.startsWith('http://') ||
                            avatarUrl.startsWith('https://'))) {
                      return Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 128,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            PhosphorIconsRegular.userCircle,
                            size: 58,
                            color: Color(0xFFCFCFCF),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return const Center(
                      child: Icon(
                        PhosphorIconsRegular.userCircle,
                        size: 58,
                        color: Color(0xFFCFCFCF),
                      ),
                    );
                  }(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildIdentityRow(
                        'Số CCCD',
                        profile['cccdNumber'] ?? 'Chưa rõ',
                      ),
                      _buildIdentityRow(
                        'Ngày sinh',
                        _formatDob(profile['dob'] ?? profile['dateOfBirth']),
                      ),
                      _buildIdentityRow(
                        'Giới tính',
                        profile['gender'] ?? 'Chưa rõ',
                      ),
                      _buildIdentityRow(
                        'Số điện thoại',
                        profile['phone'] ?? 'Chưa rõ',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDob(dynamic raw) {
    if (raw == null) return 'Chưa rõ';
    final String str = raw.toString().trim();
    if (str.isEmpty || str == 'null') return 'Chưa rõ';
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(str)) {
      return str;
    }
    try {
      final dt = DateTime.parse(str).toLocal();
      final String day = dt.day.toString().padLeft(2, '0');
      final String month = dt.month.toString().padLeft(2, '0');
      final String year = dt.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      final parts = str.split(RegExp(r'[-/]'));
      if (parts.length == 3 && parts[0].length == 4) {
        final y = parts[0];
        final m = parts[1].padLeft(2, '0');
        final d = parts[2].split('T')[0].padLeft(2, '0');
        return '$d/$m/$y';
      }
      return str;
    }
  }

  Widget _buildIdentityRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa rõ',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard(Map<String, dynamic> medical) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin y tế',
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 16),
          _buildMedicalLine('Nhóm máu', medical['bloodGroup'] ?? 'Chưa rõ'),
          _buildMedicalLine(
            'Dị ứng',
            (medical['allergies'] as List?)?.join(', ') ?? 'Không có',
          ),
          _buildMedicalLine(
            'Đơn thuốc đang dùng',
            (medical['currentMedications'] as List?)?.join(', ') ?? 'Không có',
          ),
          _buildMedicalLine(
            'Tình trạng bệnh lý',
            (medical['backgroundDiseases'] as List?)?.join(', ') ?? 'Không có',
            isLast: true,
          ),
          if (medical['notes'] != null && medical['notes'] != '') ...[
            const SizedBox(height: 16),
            const Text(
              'Ghi chú khác:',
              style: TextStyle(
                color: Color(0xFF8A8A8A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              medical['notes'],
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalLine(String title, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryBlack,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    Map<String, dynamic> profile,
    Map<String, dynamic> medical,
    List<dynamic> contacts,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: PhosphorIconsFill.phoneCall,
                  label: 'Gọi 114',
                  color: const Color(0xFF10B981),
                  onTap: () => _makeCall('114'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSecondaryButton(
                  icon: PhosphorIconsFill.usersThree,
                  label: 'Người thân',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    // Navigate to emergency contacts sub-page or show bottom sheet
                    _showContactsSheet(context, contacts);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 🚨 Emergency Action Button: "Gửi yêu cầu khẩn cấp"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showEmergencyReportSheet(context, profile, medical),
              icon: const Icon(PhosphorIconsFill.siren, size: 20, color: Colors.white),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Gửi yêu cầu khẩn cấp',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626), // Emergency Vivid Red
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                // Placeholder for Video Call
              },
              icon: const Icon(PhosphorIconsFill.videoCamera, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Video call Tổng đài hỗ trợ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 1,
                shadowColor: AppColors.primaryOrange.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyReportSheet(
    BuildContext context,
    Map<String, dynamic> profile,
    Map<String, dynamic> medical,
  ) {
    final String? victimId = profile['id'] ?? data['victimId'] ?? data['citizenId'];
    final String victimName = profile['fullName'] ?? 'Nạn nhân';
    final String bloodGroup = medical['bloodGroup'] ?? 'Chưa rõ';

    final TextEditingController descController = TextEditingController(
      text: 'Phát hiện nạn nhân cần cấp cứu khẩn cấp tại hiện trường.',
    );
    String selectedTag = 'Tai nạn giao thông';
    bool isSubmitting = false;

    // Real-Time GPS Location State
    LocationResult? currentLocation;
    bool isLocating = true;

    final List<String> quickTags = [
      'Tai nạn giao thông',
      'Bất tỉnh / Ngất xỉu',
      'Chấn thương nặng',
      'Khó thở / Co giật',
      'Đột quỵ / Đau tim',
      'Khác',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Trigger real GPS query once on sheet initialization
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
                          'Gửi yêu cầu cứu hộ khẩn cấp',
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
                        // Victim Info Preview Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
                                child: const Icon(
                                  PhosphorIconsFill.user,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      victimName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Color(0xFF881337),
                                      ),
                                    ),
                                    Text(
                                      'Nhóm máu: $bloodGroup',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'CẦN CỨU TRỢ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Real-Time GPS Location Card
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
                                              '[$tag] Cần hỗ trợ y tế khẩn cấp cho nạn nhân $victimName tại hiện trường.';
                                        });
                                      }
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Situation Details Input
                        const Text(
                          'Mô tả chi tiết hiện trường / tình trạng',
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
                            hintText: 'Nhập thông tin mô tả vết thương, vị trí...',
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
                                        victimId: victimId,
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

  void _showEmergencySuccessDialog(
    BuildContext context,
    Map<String, dynamic> reportResult,
  ) {
    final report = reportResult['report'] ?? reportResult;
    final String reportId = (report['id'] ?? reportResult['id'] ?? 'N/A').toString();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.checkCircle,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Yêu cầu cứu hộ đã được gửi!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã báo cáo: ${reportId.length > 8 ? reportId.substring(0, 8).toUpperCase() : reportId}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Thông tin vị trí định vị và hồ sơ bệnh án của nạn nhân đã được chuyển tiếp đến đội ngũ cứu hộ và thông báo tự động đến người thân.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactsSheet(BuildContext context, List<dynamic> contacts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFF2E7DB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: const Row(
                children: [
                  Icon(
                    PhosphorIconsFill.usersThree,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Liên hệ người thân',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryOrange.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            PhosphorIconsFill.user,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                contact['relationship'] ?? 'N/A',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _makeCall(contact['phoneNumber'] ?? ''),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              PhosphorIconsFill.phoneCall,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
