import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';
import 'package:help_me_app/widgets/otp_input_widget.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class StaffSignInPage extends StatefulWidget {
  const StaffSignInPage({super.key});

  @override
  State<StaffSignInPage> createState() => _StaffSignInPageState();
}

class _StaffSignInPageState extends State<StaffSignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _currentStep = 1; // 1: Login, 2: OTP
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleStaffLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Giả lập hoặc thực tế gọi backend.
      // Để demo đúng thiết kế cho USER nhanh nhất, tôi sẽ chuyển sang bước OTP ngay.
      // await AuthService.staffSignIn(email, password);

      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Hơi delay cho feeling thực tế

      if (mounted) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp(String otp) async {
    setState(() => _isLoading = true);
    try {
      // Thực hiện logic xác thực OTP ở đây (nếu backend có)
      // Hiện tại giả lập để hoàn tất luồng
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mã OTP không hợp lệ')));
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F9F5),
      body: Stack(
        children: [
          // Decorative Arcs
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                color: Color(0xFFB9F2E2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                color: Color(0xFFB9F2E2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Branding
                  SvgPicture.asset('assets/logo.svg', width: 140),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        letterSpacing: -0.5,
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
                  const SizedBox(height: 30),

                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _currentStep == 1
                        ? _buildLoginStep()
                        : _buildOtpStep(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryBlack,
                ),
                onPressed: () {
                  if (_currentStep == 2) {
                    setState(() => _currentStep = 1);
                  } else {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/sign-in');
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginStep() {
    return Column(
      children: [
        const Text(
          'Đăng nhập',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 40),
        CustomTextField(
          controller: _emailController,
          hintText: 'Địa chỉ email',
          prefixIcon: const Icon(
            PhosphorIconsRegular.envelope,
            color: AppColors.primaryOrange,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          hintText: 'Mật khẩu',
          obscureText: !_isPasswordVisible,
          prefixIcon: const Icon(
            PhosphorIconsRegular.password,
            color: AppColors.primaryOrange,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? PhosphorIconsRegular.eye
                  : PhosphorIconsRegular.eyeSlash,
              color: Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleStaffLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 40),
        _buildFooterLink(),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const Text(
          'Xác nhận OTP',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 40),
        OtpInputWidget(length: 6, onCompleted: (otp) => _handleVerifyOtp(otp)),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic xác nhận OTP
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                // Logic gửi lại OTP
              },
              icon: const Icon(
                PhosphorIconsRegular.arrowCounterClockwise,
                size: 20,
                color: AppColors.primaryBlack,
              ),
              label: const Text(
                'Gửi lại',
                style: TextStyle(
                  color: AppColors.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildFooterLink(),
      ],
    );
  }

  Widget _buildFooterLink() {
    return GestureDetector(
      onTap: () => context.go('/sign-in'),
      child: const Text(
        'Bạn là công dân? Đăng nhập tại đây!',
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
