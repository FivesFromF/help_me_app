import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/pages/profile/emergency_contacts_page.dart';
import 'package:help_me_app/pages/profile/medical_record_page.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  int _activeTab = 0;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final profileData = await AuthService.getCachedProfile();
      if (profileData != null && profileData['citizen'] != null) {
        final citizen = CitizenProfile.fromJson(profileData['citizen']);

        // Nếu chưa khai báo thông tin cơ bản -> Chuyển hướng đến trang hoàn thiện hồ sơ
        if (!citizen.firstDeclareProfile && mounted) {
          Future.microtask(() {
            if (mounted) context.pushReplacement('/auth/sign-up');
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking profile status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hồ sơ người dùng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFEDE1D3),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Hồ sơ y tế',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _activeTab == 0
                                  ? AppColors.primaryOrange
                                  : AppColors.primaryBlack,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? AppColors.primaryOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Thông tin người thân',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _activeTab == 1
                                  ? AppColors.primaryOrange
                                  : AppColors.primaryBlack,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? AppColors.primaryOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
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
