import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';

class SignUpPhonePage extends StatelessWidget {
  const SignUpPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Đăng ký',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đăng ký với SĐT:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 20),
            const CustomTextField(
              hintText: 'Nhập số điện thoại',
              keyboardType: TextInputType.phone,
              prefixIcon: Icon(PhosphorIconsFill.phone,
                  color: AppColors.primaryOrange),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/auth/otp-verification', extra: {
                    'title': 'Đăng ký với SĐT: 0362718422',
                    'subtitle': 'Mã OTP đã được gửi về số điện thoại của bạn',
                    'onConfirm': () => context.go('/home'),
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Gửi mã OTP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
