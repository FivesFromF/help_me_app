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
        // Nếu đã login, vào thẳng Home
        context.go('/home');
      } else {
        // Chưa login, ra màn hình Sign In
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
          // Decorative Elements
          Positioned(
            top: -200,
            left: -200,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.05),
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
                    width: 160, 
                    height: 160
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                      letterSpacing: -1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Help',
                        style: TextStyle(color: AppColors.primaryBlack),
                      ),
                      TextSpan(
                        text: 'Me',
                        style: TextStyle(color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ỨNG DỤNG HỖ TRỢ Y TẾ KHẨN CẤP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Loading Indicator
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
