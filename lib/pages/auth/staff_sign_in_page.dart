import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';
import 'package:help_me_app/widgets/otp_input_widget.dart';

class StaffSignInPage extends StatefulWidget {
  const StaffSignInPage({super.key});

  @override
  State<StaffSignInPage> createState() => _StaffSignInPageState();
}

class _StaffSignInPageState extends State<StaffSignInPage> {
  int _currentStep = 0; // 0: Login, 1: OTP

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Circles (Static)
          Positioned(
            top: -250,
            left: -250,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo (Static)
                    SvgPicture.asset('assets/logo.svg', width: 120),
                    const SizedBox(height: 10),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(
                            text: 'Sinh mệnh ',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                          TextSpan(
                            text: 'Khẩn cấp',
                            style: TextStyle(color: AppColors.primaryOrange),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Card (Dynamic Content)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentStep == 0
                              ? _buildLoginStep()
                              : _buildOtpStep(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Back button for Steps > 0
          if (_currentStep > 0)
            Positioned(
              top: 40,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
                onPressed: _prevStep,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginStep() {
    return Column(
      key: const ValueKey(0),
      children: [
        const Text(
          'Đăng nhập',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 40),
        const CustomTextField(
          hintText: 'Địa chỉ email',
          prefixIcon: Icon(
            PhosphorIconsFill.envelope,
            color: AppColors.primaryOrange,
          ),
        ),
        const SizedBox(height: 20),
        const CustomTextField(
          hintText: 'Mật khẩu',
          obscureText: true,
          prefixIcon: Icon(
            PhosphorIconsFill.key,
            color: AppColors.primaryOrange,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 100),
        Text.rich(
          TextSpan(
            text: 'Bạn là công dân? ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            children: [
              TextSpan(
                text: 'Đăng nhập tại đây!',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.go('/sign-in'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        const Text(
          'Xác nhận OTP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 40),
        OtpInputWidget(
          onCompleted: (otp) {},
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            TextButton.icon(
              onPressed: () {},
              icon: const Text('Gửi lại',
                  style: TextStyle(
                      color: AppColors.primaryBlack,
                      fontWeight: FontWeight.bold)),
              label: const Icon(PhosphorIconsRegular.arrowClockwise,
                  color: AppColors.primaryBlack),
            ),
          ],
        ),
        const SizedBox(height: 100),
        Text.rich(
          TextSpan(
            text: 'Bạn là công dân? ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            children: [
              TextSpan(
                text: 'Đăng nhập tại đây!',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.go('/sign-in'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
