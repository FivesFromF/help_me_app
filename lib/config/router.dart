import 'package:go_router/go_router.dart';
import 'package:help_me_app/pages/auth/sign_in_page.dart';
import 'package:help_me_app/pages/auth/sign_up/sign_up_personal_info_page.dart';
import 'package:help_me_app/pages/auth/sign_up/sign_up_id_info_page.dart';
import 'package:help_me_app/pages/auth/sign_up/sign_up_phone_page.dart';
import 'package:help_me_app/pages/auth/staff_sign_in_page.dart';
import 'package:help_me_app/pages/auth/otp_verification_page.dart';
import '../pages/home/splash_screen_page.dart';
import '../pages/home/home_page.dart';
import '../pages/details_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreenPage()),
    GoRoute(path: '/sign-in', builder: (context, state) => const SignInPage()),
    GoRoute(
        path: '/auth/staff-sign-in',
        builder: (context, state) => const StaffSignInPage()),
    GoRoute(
      path: '/auth/otp-verification',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpVerificationPage(
          title: extra?['title'] ?? 'Xác nhận OTP',
          subtitle: extra?['subtitle'],
          onConfirm: extra?['onConfirm'] ?? () {},
        );
      },
    ),
    GoRoute(
        path: '/auth/sign-up-personal-info',
        builder: (context, state) => const SignUpPersonalInfoPage()),
    GoRoute(
        path: '/auth/sign-up-id-info',
        builder: (context, state) => const SignUpIdInfoPage()),
    GoRoute(
        path: '/auth/sign-up-phone',
        builder: (context, state) => const SignUpPhonePage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/details/:message',
      builder: (context, state) {
        final message = state.pathParameters['message'] ?? 'No message';
        return DetailsPage(message: message);
      },
    ),
  ],
);
