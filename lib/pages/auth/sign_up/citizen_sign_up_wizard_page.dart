import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';
import 'package:help_me_app/widgets/otp_input_widget.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class CitizenSignUpWizardPage extends StatefulWidget {
  const CitizenSignUpWizardPage({super.key});

  @override
  State<CitizenSignUpWizardPage> createState() => _CitizenSignUpWizardPageState();
}

class _CitizenSignUpWizardPageState extends State<CitizenSignUpWizardPage> {
  int _currentStep = 0;
  bool _isLoading = false;

  // State Data
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _otpCode = '';
  String _jwtToken = ''; // Passed to Register profile after OTP verify

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    final response = await AuthService.requestOTP(phone);
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() => _currentStep = 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response['error'] ?? "Thử lại sau!"}')),
      );
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpCode.length < 6) return;

    setState(() => _isLoading = true);
    final response = await AuthService.verifyOTP(_phoneController.text.trim(), _otpCode);
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'];
      final profile = data['profile'];

      if (profile != null) {
        // Profile already exists -> go to home
        context.go('/home');
      } else {
        // Needs profile setup -> continue to Step 2
        setState(() {
          _jwtToken = token;
          _currentStep = 2;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sai mã OTP: ${response['error']}')),
      );
    }
  }

  Future<void> _handleRegisterProfile() async {
    // In real app: Validate text fields, then send via _jwtToken in header
    // Currently relying on backend gRPC mapping and AuthService extensions
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Placeholder for actual register API
    setState(() => _isLoading = false);

    // After success:
    context.go('/home');
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('step0_phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đăng ký với Số điện thoại:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _phoneController,
          hintText: 'Nhập số điện thoại',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(PhosphorIconsFill.phone, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 40),
        _buildActionButton('Gửi mã OTP', _handleRequestOTP),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      key: const ValueKey('step1_otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryBlack,
              fontFamily: 'Inter',
            ),
            children: [
              const TextSpan(text: 'Nhập mã xác nhận gửi tới: '),
              TextSpan(
                text: _phoneController.text,
                style: const TextStyle(
                  color: Color(0xFF00B14F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        OtpInputWidget(
          length: 6,
          onCompleted: (otp) {
            setState(() => _otpCode = otp);
            _handleVerifyOTP();
          },
        ),
        const SizedBox(height: 40),
        _buildActionButton('Xác thực', _handleVerifyOTP),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      key: const ValueKey('step2_info'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoàn thiện Hồ sơ Y tế (Bắt buộc):',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _fullNameController,
          hintText: 'Họ và tên',
          prefixIcon: const Icon(PhosphorIconsRegular.userCircle, color: AppColors.primaryOrange),
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
          hintText: 'Giới tính (Nam/Nữ)',
          prefixIcon: const Icon(PhosphorIconsRegular.genderMale, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _addressController,
          hintText: 'Nơi ở hiện tại',
          prefixIcon: const Icon(PhosphorIconsRegular.house, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _emailController,
          hintText: 'Email (Tùy chọn)',
          prefixIcon: const Icon(PhosphorIconsRegular.envelope, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 40),
        _buildActionButton('Hoàn thành', _handleRegisterProfile),
      ],
    );
  }

  Widget _buildActionButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressColor(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            if (_currentStep > 0 && _currentStep < 2) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Đăng ký Citizen',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _currentStep == 0
                ? _buildPhoneStep()
                : _currentStep == 1
                    ? _buildOTPStep()
                    : _buildPersonalInfoStep(),
          ),
        ),
      ),
    );
  }
}

class CircularProgressColor extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  const CircularProgressColor({super.key, required this.color, required this.strokeWidth});
  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(color), strokeWidth: strokeWidth);
  }
}
