import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/widgets/custom_text_field.dart';
import 'package:help_me_app/shared/services/auth_service.dart';

class CitizenBasicInfoPage extends StatefulWidget {
  const CitizenBasicInfoPage({super.key});

  @override
  State<CitizenBasicInfoPage> createState() => _CitizenBasicInfoPageState();
}

class _CitizenBasicInfoPageState extends State<CitizenBasicInfoPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profileData = await AuthService.getCachedProfile();
    if (profileData != null && profileData['citizen'] != null) {
      final citizen = profileData['citizen'];
      setState(() {
        // We only pre-fill email, Name is left for user to type manually
        _emailController.text = citizen['email'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _handleComplete() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      _showError('Vui lòng nhập họ và tên');
      return;
    }
    if (_dobController.text.isEmpty) {
      _showError('Vui lòng chọn ngày sinh');
      return;
    }
    if (_selectedGender == null) {
      _showError('Vui lòng chọn giới tính');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'fullName': fullName,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'gender': _selectedGender,
        'address': _addressController.text.trim(),
        'firstDeclareProfile': true,
      };

      await AuthService.completeCitizenProfile(data);

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi cập nhật: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () => context.go('/sign-in'),
        ),
        title: const Text(
          'Hoàn thiện hồ sơ',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chào mừng bạn đến với Help Me! 👋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chỉ cần vài thông tin cơ bản nữa là chúng ta có thể bắt đầu rồi.',
              style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 32),

            _buildFieldHeader('Họ và tên'),
            CustomTextField(
              controller: _fullNameController,
              hintText: 'Nhập họ và tên thật của bạn',
              prefixIcon: const Icon(
                PhosphorIconsRegular.user,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),

            _buildFieldHeader('Email (Cố định)'),
            CustomTextField(
              controller: _emailController,
              hintText: 'Email',
              enabled: false,
              prefixIcon: const Icon(
                PhosphorIconsRegular.envelope,
                color: Color(0xFFBBBBBB),
              ),
            ),
            const SizedBox(height: 20),

            _buildFieldHeader('Số điện thoại'),
            CustomTextField(
              controller: _phoneController,
              hintText: 'Nhập số điện thoại của bạn',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(
                PhosphorIconsRegular.phone,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldHeader('Ngày sinh'),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: _dobController,
                            hintText: 'Chọn ngày',
                            prefixIcon: const Icon(
                              PhosphorIconsRegular.calendar,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldHeader('Giới tính'),
                      _buildGenderDropdown(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildFieldHeader('Nơi ở hiện tại'),
            CustomTextField(
              controller: _addressController,
              hintText: 'Nhập địa chỉ của bạn',
              prefixIcon: const Icon(
                PhosphorIconsRegular.mapPin,
                color: AppColors.primaryOrange,
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 48),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBlack,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(
            border: InputBorder.none,
            icon: Icon(
              PhosphorIconsRegular.genderIntersex,
              color: AppColors.primaryOrange,
            ),
          ),
          hint: const Text(
            'Chọn',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          ),
          items: ['Nam', 'Nữ', 'Khác'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.primaryBlack,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ),
    );
  }
}
