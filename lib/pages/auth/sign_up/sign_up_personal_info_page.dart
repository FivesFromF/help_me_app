import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';

class SignUpPersonalInfoPage extends StatelessWidget {
  const SignUpPersonalInfoPage({super.key});

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin cá nhân:',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 20),
              const CustomTextField(
                hintText: 'Họ và tên',
                prefixIcon: Icon(PhosphorIconsRegular.userCircle,
                    color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 15),
              const CustomTextField(
                hintText: 'Ngày sinh',
                prefixIcon: Icon(PhosphorIconsRegular.calendar,
                    color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 15),
              const CustomTextField(
                hintText: 'Giới tính',
                prefixIcon: Icon(PhosphorIconsRegular.genderMale,
                    color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 15),
              const CustomTextField(
                hintText: 'Nơi ở',
                prefixIcon: Icon(PhosphorIconsRegular.house,
                    color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 15),
              const CustomTextField(
                hintText: 'Email',
                prefixIcon: Icon(PhosphorIconsRegular.envelope,
                    color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 150),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/auth/sign-up-id-info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục',
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
      ),
    );
  }
}
