import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Để Splash Screen hiển thị ít nhất 2 giây cho premium feel
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Kiểm tra trạng thái đăng nhập
    final loggedIn = await AuthService.isLoggedIn();
    
    if (mounted) {
      if (loggedIn) {
        try {
          // Lấy profile mới nhất để kiểm tra các flag trạng thái
          print('SplashScreen: Fetching latest profile...');
          final res = await AuthService.fetchAndCacheProfile();
          final citizen = res['profile'];
          
          print('SplashScreen: Profile data: $citizen');

          if (citizen != null) {
            final bool firstDeclare = citizen['firstDeclareProfile'] ??
                citizen['first_declare_profile'] ??
                false;
            final bool consent = citizen['consentRegulation'] ??
                citizen['consent_regulation'] ??
                false;

            print('SplashScreen: firstDeclare=$firstDeclare, consent=$consent');

            if (!firstDeclare) {
              print('SplashScreen: Redirecting to /auth/sign-up');
              context.go('/auth/sign-up');
            } else if (!consent) {
              print('SplashScreen: Redirecting to /privacy');
              context.go('/privacy?consent=true');
            } else {
              print('SplashScreen: Redirecting to /home');
              context.go('/home');
            }
          } else {
            print('SplashScreen: Profile is null, redirecting to /sign-in');
            context.go('/sign-in');
          }
        } catch (e) {
          print('SplashScreen: Error fetching profile: $e');
          // In case of error, better to sign in again than bypass
          context.go('/sign-in');
        }
      } else {
        print('SplashScreen: Not logged in, redirecting to /sign-in');
        context.go('/sign-in');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Teal Decorative Arcs
          Positioned(
            top: -240,
            left: -120,
            child: Container(
              width: 480,
              height: 480,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F9F5), // Light Mint Background
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -180,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                color: Color(0xFFB9F2E2), // Mint Arc
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -280,
            right: -140,
            child: Container(
              width: 560,
              height: 560,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F9F5), // Light Mint Background
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                color: Color(0xFFB9F2E2), // Mint Arc
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Central Logo & Name
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    width: 180,
                    height: 180,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

