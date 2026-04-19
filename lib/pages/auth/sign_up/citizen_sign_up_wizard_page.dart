import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class CitizenSignUpWizardPage extends StatefulWidget {
  const CitizenSignUpWizardPage({super.key});

  @override
  State<CitizenSignUpWizardPage> createState() => _CitizenSignUpWizardPageState();
}

class _CitizenSignUpWizardPageState extends State<CitizenSignUpWizardPage> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cccdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profileData = await AuthService.getCachedProfile();
    if (profileData != null && profileData['citizen'] != null) {
      final citizen = profileData['citizen'];
      setState(() {
        _fullNameController.text = citizen['fullName'] ?? '';
        _phoneController.text = citizen['phone'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _cccdController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteProfile() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ và tên')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'fullName': fullName,
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'gender': _genderController.text.trim(),
        'address': _addressController.text.trim(),
        'cccdNumber': _cccdController.text.trim(),
      };

      await AuthService.completeCitizenProfile(data);
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStep0() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cá nhân cơ bản:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 25),
        CustomTextField(
          controller: _fullNameController,
          hintText: 'Họ và tên',
          prefixIcon: const Icon(PhosphorIconsRegular.user, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _dobController,
          hintText: 'Ngày sinh (YYYY-MM-DD)',
          prefixIcon: const Icon(PhosphorIconsRegular.calendar, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _genderController,
          hintText: 'Giới tính',
          prefixIcon: const Icon(PhosphorIconsRegular.genderIntersex, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 40),
        _buildActionButton('Tiếp theo', () => setState(() => _currentStep = 1)),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin định danh và liên hệ:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 25),
        CustomTextField(
          controller: _cccdController,
          hintText: 'Số CCCD / CMND',
          prefixIcon: const Icon(PhosphorIconsRegular.identificationCard, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _addressController,
          hintText: 'Địa chỉ thường trú',
          prefixIcon: const Icon(PhosphorIconsRegular.mapPin, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _phoneController,
          hintText: 'Số điện thoại liên lạc',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(PhosphorIconsRegular.phoneCircle, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 40),
        _buildActionButton('Hoàn tất hồ sơ', _handleCompleteProfile),
      ],
    );
  }

  Widget _buildActionButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        title: const Text(
          'Hoàn thiện hồ sơ',
          style: TextStyle(color: AppColors.primaryBlack, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Step indicator
            Row(
              children: [
                _buildDot(_currentStep >= 0),
                _buildLine(_currentStep >= 1),
                _buildDot(_currentStep >= 1),
              ],
            ),
            const SizedBox(height: 30),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentStep == 0 ? _buildStep0() : _buildStep1(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryOrange : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? AppColors.primaryOrange : Colors.grey.shade300,
      ),
    );
  }
}
