import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/pages/profile/emergency_contacts_page.dart';
import 'package:help_me_app/pages/profile/medical_record_page.dart';

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hồ sơ người dùng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFEDE1D3),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Hồ sơ y tế',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _activeTab == 0
                                ? AppColors.primaryOrange
                                : AppColors.primaryBlack,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          thickness: 3,
                          height: 3,
                          color: _activeTab == 0
                              ? AppColors.primaryOrange
                              : Colors.transparent,
                          indent: 20,
                          endIndent: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Thông tin người thân',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _activeTab == 1
                                ? AppColors.primaryOrange
                                : AppColors.primaryBlack,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          thickness: 3,
                          height: 3,
                          color: _activeTab == 1
                              ? AppColors.primaryOrange
                              : Colors.transparent,
                          indent: 20,
                          endIndent: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: const [
                MedicalRecordPage(showScaffold: false),
                EmergencyContactsPage(showScaffold: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
