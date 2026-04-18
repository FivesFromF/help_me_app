import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';

class IdInfoWidget extends StatelessWidget {
  final VoidCallback? onNext;

  const IdInfoWidget({
    super.key,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin CCCD/ ID:',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          5,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: CustomTextField(
              hintText: 'CCCD',
              prefixIcon: Icon(PhosphorIconsRegular.identificationCard,
                  color: AppColors.primaryOrange),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.secondaryBlack),
          ),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tài khoản định danh điện tử',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Image.asset('assets/vneid_logo.png', height: 30),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Hoặc',
                        style: TextStyle(color: AppColors.primaryGreen)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(PhosphorIconsRegular.qrCode,
                          size: 40, color: AppColors.primaryGreen),
                      const SizedBox(height: 8),
                      const Text('Quét thẻ\nNFC CCCD',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(PhosphorIconsRegular.scan,
                          size: 40, color: AppColors.primaryGreen),
                      const SizedBox(height: 8),
                      const Text('Quét QR\nCCCD',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onNext != null) ...[
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
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
      ],
    );
  }
}
