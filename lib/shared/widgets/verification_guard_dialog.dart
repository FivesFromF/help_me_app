import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';

class VerificationGuardDialog extends StatelessWidget {
  const VerificationGuardDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const VerificationGuardDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Icon with Gradient-like circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsFill.shieldWarning,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Xác thực tài khoản',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlack,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn cần xác thực tài khoản bằng CCCD hoặc VNeID để sử dụng các tính năng quan trọng như lập hồ sơ y tế.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            // Primary Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/profile/verification');
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
                  'Xác thực ngay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF888888),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Để sau',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
