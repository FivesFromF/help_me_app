import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class StaffSignInPage extends StatefulWidget {
  const StaffSignInPage({super.key});

  @override
  State<StaffSignInPage> createState() => _StaffSignInPageState();
}

class _StaffSignInPageState extends State<StaffSignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _showOTPField = false;

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
      final res = await AuthService.staffSignIn(email, password);
      // In multi-step flow, res['token'] might be empty string or null 
      // when password is correct but OTP is sent.
      if (mounted) {
        if (res['token'] != null && res['token'].toString().isNotEmpty) {
          // Immediate login (no MFA or pre-verified)
          context.go('/home');
        } else {
          // Password accepted, waiting for OTP
          setState(() {
            _showOTPField = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mật khẩu chính xác. Vui lòng nhập mã OTP đã gửi đến SĐT của bạn.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerifyOTP() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã OTP 6 chữ số')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Reusing verifyOTP endpoint - backend handler logic now supports email too
      final res = await AuthService.verifyOTP(email, otp);
      if (mounted) {
        if (res['token'] != null) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mã OTP không hợp lệ hoặc đã hết hạn: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Circles (Keeping same UI)
          Positioned(top: -250, left: -250,
            child: Container(width: 500, height: 500, decoration: BoxDecoration(color: AppColors.secondaryGreen.withOpacity(0.4), shape: BoxShape.circle))),
          Positioned(top: -150, left: -150,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.secondaryGreen.withOpacity(0.6), shape: BoxShape.circle))),
          Positioned(bottom: -200, right: -150,
            child: Container(width: 600, height: 600, decoration: BoxDecoration(color: AppColors.secondaryGreen.withOpacity(0.3), shape: BoxShape.circle))),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SvgPicture.asset('assets/logo.svg', width: 120),
                    const SizedBox(height: 10),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        children: [
                          TextSpan(text: 'Sinh mệnh ', style: TextStyle(color: AppColors.primaryGreen)),
                          TextSpan(text: 'Khẩn cấp', style: TextStyle(color: AppColors.primaryOrange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _showOTPField ? _buildOTPForm() : _buildLoginForm(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
              onPressed: () {
                if (_showOTPField) {
                  setState(() => _showOTPField = false);
                } else {
                  context.go('/sign-in');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('LoginForm'),
      children: [
        const Text('Nhân viên y tế', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlack)),
        const SizedBox(height: 40),
        CustomTextField(
          controller: _emailController,
          hintText: 'Địa chỉ email',
          prefixIcon: const Icon(PhosphorIconsFill.envelope, color: AppColors.primaryOrange, size: 24),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passwordController,
          hintText: 'Mật khẩu',
          obscureText: true,
          prefixIcon: const Icon(PhosphorIconsFill.key, color: AppColors.primaryOrange, size: 24),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleStaffLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _isLoading ? _buildLoading() : const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 30),
        _buildSwitchToCitizen(),
      ],
    );
  }

  Widget _buildOTPForm() {
    return Column(
      key: const ValueKey('OTPForm'),
      children: [
        const Text('Xác minh OTP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlack)),
        const SizedBox(height: 10),
        Text('Mã OTP đã được gửi đến SĐT liên kết với email ${_emailController.text}', 
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 40),
        CustomTextField(
          controller: _otpController,
          hintText: 'Mã xác thực 6 số',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(PhosphorIconsFill.shieldCheck, color: AppColors.primaryOrange, size: 24),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOTP,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: _isLoading ? _buildLoading() : const Text('Xác nhận & Đăng nhập', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _isLoading ? null : _handleStaffLogin,
          child: const Text('Gửi lại mã OTP', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
  }

  Widget _buildSwitchToCitizen() {
    return Text.rich(
      TextSpan(
        text: 'Bạn là công dân? ',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        children: [
          TextSpan(
            text: 'Đăng nhập tại đây!',
            style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () => context.go('/sign-in'),
          ),
        ],
      ),
    );
  }
}
