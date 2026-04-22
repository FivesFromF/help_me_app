import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool profileAccessAlert = true;
  bool deviceLinkAlert = true;
  bool periodicHealthUpdate = true;
  bool emergencyContactConfirm = true;
  bool featureNews = true;
  bool safetyTips = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryOrange,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryOrange,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _NotificationGroup(
              icon: PhosphorIconsRegular.lock,
              title: 'Cảnh báo Khẩn cấp & Bảo mật',
              children: [
                _ToggleRow(
                  label: 'Cảnh báo truy xuất hồ sơ',
                  value: profileAccessAlert,
                  onChanged: (value) =>
                      setState(() => profileAccessAlert = value),
                ),
                _ToggleRow(
                  label: 'Cảnh báo thiết bị liên kết',
                  value: deviceLinkAlert,
                  onChanged: (value) => setState(() => deviceLinkAlert = value),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _NotificationGroup(
              icon: PhosphorIconsRegular.heart,
              title: 'Nhắc nhở Y tế & Cứu trợ khẩn cấp',
              children: [
                _ToggleRow(
                  label: 'Cập nhật hồ sơ y tế định kỳ',
                  value: periodicHealthUpdate,
                  onChanged: (value) =>
                      setState(() => periodicHealthUpdate = value),
                ),
                _ToggleRow(
                  label: 'Xác nhận liên hệ khẩn cấp',
                  value: emergencyContactConfirm,
                  onChanged: (value) =>
                      setState(() => emergencyContactConfirm = value),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _NotificationGroup(
              icon: PhosphorIconsRegular.squaresFour,
              title: 'Cập nhật Hệ thống',
              children: [
                _ToggleRow(
                  label: 'Tin tức & Tính năng mới',
                  value: featureNews,
                  onChanged: (value) => setState(() => featureNews = value),
                ),
                _ToggleRow(
                  label: 'Mẹo an toàn cộng đồng',
                  value: safetyTips,
                  onChanged: (value) => setState(() => safetyTips = value),
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primaryBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primaryGreen,
                activeTrackColor: AppColors.primaryGreen.withAlpha(50),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}
