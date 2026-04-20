import 'package:go_router/go_router.dart';
import 'package:help_me_app/pages/auth/sign_in/sign_in_page.dart';
import 'package:help_me_app/pages/auth/sign_up/citizen_basic_info_page.dart';
import 'package:help_me_app/pages/auth/sign_in/staff_sign_in_page.dart';
import '../pages/home/splash_screen_page.dart';
import '../pages/home/home_page.dart';
import '../pages/details_page.dart';
import '../pages/support/support_page.dart';
import '../pages/privacy/privacy_policy_page.dart';
import '../pages/notifications/notifications_page.dart';
import '../pages/settings/how_to_use_page.dart';
import '../pages/profile/medical_record_page.dart';
import '../pages/profile/emergency_contacts_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreenPage()),
    GoRoute(path: '/sign-in', builder: (context, state) => const SignInPage()),
    GoRoute(
      path: '/auth/staff-sign-in',
      builder: (context, state) => const StaffSignInPage(),
    ),

    // Màn hình hoàn thiện hồ sơ cơ bản (Citizen Basic Info - Single Page)
    GoRoute(
      path: '/auth/sign-up',
      builder: (context, state) => const CitizenBasicInfoPage(),
    ),

    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          const HomePage(), // placeholder; settings opened from home currently
    ),
    GoRoute(path: '/support', builder: (context, state) => const SupportPage()),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/how-to-use',
      builder: (context, state) => const HowToUsePage(),
    ),

    GoRoute(
      path: '/profile/medical-record',
      builder: (context, state) => const MedicalRecordPage(),
    ),
    GoRoute(
      path: '/profile/emergency-contacts',
      builder: (context, state) => const EmergencyContactsPage(),
    ),
    GoRoute(
      path: '/details/:message',
      builder: (context, state) {
        final message = state.pathParameters['message'] ?? 'No message';
        return DetailsPage(message: message);
      },
    ),
  ],
);
