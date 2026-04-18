import 'package:flutter/material.dart';
import 'package:help_me_app/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final Widget prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: prefixIcon,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.secondaryBlack),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.secondaryBlack),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryOrange),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
