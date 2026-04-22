import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class IdentityResultPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const IdentityResultPage({super.key, required this.data});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = data['profile'] ?? {};
    final medical = data['medicalRecord'] ?? {};
    final List<dynamic> contacts = data['emergencyContacts'] ?? [];

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
          _buildActionSection(context, contacts),
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
                    image:
                        profile['avatarUrl'] != null &&
                            profile['avatarUrl'] != ''
                        ? DecorationImage(
                            image: NetworkImage(profile['avatarUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      profile['avatarUrl'] == null || profile['avatarUrl'] == ''
                      ? const Icon(
                          PhosphorIconsRegular.userCircle,
                          size: 58,
                          color: Color(0xFFCFCFCF),
                        )
                      : null,
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
                        profile['dob'] ?? 'Chưa rõ',
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

  Widget _buildIdentityRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8A8A8A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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

  Widget _buildActionSection(BuildContext context, List<dynamic> contacts) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: () {
                // Placeholder for Video Call
              },
              icon: const Icon(PhosphorIconsFill.videoCamera, size: 28),
              label: const Text(
                'Video call Tổng đài hỗ trợ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primaryOrange.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
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
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
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
