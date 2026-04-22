import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final res = await AuthService.signInWithGoogle();
      if (mounted) {
        // Kiểm tra xem user đã hoàn thiện profile chưa
        // Nếu fullName vẫn là email hoặc rỗng (do tự động provision)
        // Hoặc dựa vào một flag trong profile trả về
        final citizen = res['citizen'];
          print('SignInPage: Profile data: $citizen');
          if (citizen != null) {
            final bool firstDeclare =
                citizen['firstDeclareProfile'] ??
                citizen['first_declare_profile'] ??
                false;
            final bool consent =
                citizen['consentRegulation'] ??
                citizen['consent_regulation'] ??
                false;

            print('SignInPage: firstDeclare=$firstDeclare, consent=$consent');

            if (!firstDeclare) {
              print('SignInPage: Redirecting to /auth/sign-up');
              context.go('/auth/sign-up');
            } else if (!consent) {
              print('SignInPage: Redirecting to /privacy');
              context.go('/privacy?consent=true');
            } else {
              print('SignInPage: Redirecting to /home');
              context.go('/home');
            }
          } else {
            print('SignInPage: Citizen is null, redirecting to sign-up');
            context.go('/auth/sign-up');
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F9F5), // Light Mint Background
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
                color: Color(0xFFB9F2E2), // Mint Arc
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
                color: Color(0xFFB9F2E2), // Mint Arc
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
                  // App Branding
                  SvgPicture.asset('assets/logo.svg', width: 140, height: 140),
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

                  // Login Card
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
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

                        // Google Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Đăng nhập bằng Google',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.primaryBlack,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SvgPicture.network(
                                        'https://www.vectorlogo.zone/logos/google/google-icon.svg',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade200),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Hoặc',
                                style: TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade200),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // VNeID Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Placeholder for VNeID
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Tài khoản định danh điện tử',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  'assets/vneid_logo.png',
                                  height: 32,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        // Footer Links
                        Column(
                          children: [
                            // GestureDetector(
                            //   onTap: () => context.go('/auth/sign-up'),
                            //   child: const Text(
                            //     'Bạn chưa có tài khoản? Đăng ký tại đây!',
                            //     style: TextStyle(
                            //       color: AppColors.primaryGreen,
                            //       fontWeight: FontWeight.w600,
                            //       fontSize: 14,
                            //       decoration: TextDecoration.underline,
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => context.push('/auth/staff-sign-in'),
                              child: const Text(
                                'Bạn là nhân viên y tế? Đăng nhập tại đây!',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
