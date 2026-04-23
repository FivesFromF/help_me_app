import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/pages/profile/emergency_contacts_page.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';
import 'package:help_me_app/shared/models/medical_record.dart';
import 'package:help_me_app/pages/auth/sign_up/face_enrollment_page.dart';
import 'package:help_me_app/shared/widgets/verification_guard_dialog.dart';

import 'package:help_me_app/pages/profile/nfc_management_page.dart';
import 'package:help_me_app/pages/profile/qr_management_page.dart';

class MedicalRecordPage extends StatefulWidget {
  const MedicalRecordPage({super.key, this.showScaffold = true});
  final bool showScaffold;

  @override
  State<MedicalRecordPage> createState() => _MedicalRecordPageState();
}

class _MedicalRecordPageState extends State<MedicalRecordPage> {
  static const List<String> _drugAllergyOptions = [
    'Thuốc kháng sinh Penicillin',
    'Các loại kháng sinh khác',
    'Thuốc chống viêm',
    'Thuốc Aspirin',
    'Thuốc cản quang',
    'Thuốc giãn cơ (thuốc gây mê)',
  ];
  static const List<String> _foodAllergyOptions = [
    'Đậu phộng',
    'Các loại hạt khác',
    'Hải sản',
  ];
  static const List<String> _medicationOptions = [
    'Paracetamol',
    'Amoxicillin',
    'Metformin',
    'Amlodipine',
    'Omeprazole',
    'Vitamin tổng hợp',
  ];
  static const List<String> _diseaseOptions = [
    'Tăng huyết áp',
    'Đái tháo đường',
    'Hen phế quản',
    'Bệnh tim mạch',
    'Bệnh thận mạn',
    'Rối loạn mỡ máu',
  ];

  late CitizenProfile _profile;
  late MedicalRecord _medicalRecord;
  bool _isLoading = true;

  // Controllers for Tab 1 (Personal)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cccdController = TextEditingController();
  String _gender = 'Nam';

  // Controllers for Tab 2 (Medical)
  String _bloodGroup = 'A+';
  final TextEditingController _marksController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<String> _allergies = [];
  List<String> _diseases = [];
  List<String> _medications = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final cached = await AuthService.getCachedProfile();
      if (cached != null && cached['citizen'] != null) {
        _profile = CitizenProfile.fromJson(cached['citizen']);
        _nameController.text = _profile.fullName;
        _phoneController.text = _profile.phone;
        _dobController.text = _profile.dateOfBirth;
        _addressController.text = _profile.address;
        _cccdController.text = _profile.cccdNumber;
        _gender = _profile.gender.isNotEmpty ? _profile.gender : 'Nam';
      }

      final medData = await AuthService.getMedicalRecord();
      if (medData['record'] != null) {
        _medicalRecord = MedicalRecord.fromJson(medData['record']);
        _bloodGroup = _medicalRecord.bloodGroup.isNotEmpty
            ? _medicalRecord.bloodGroup
            : 'A+';
        _marksController.text = _medicalRecord.distinguishingMarks;
        _notesController.text = _medicalRecord.notes;
        _allergies = List.from(_medicalRecord.allergies);
        _diseases = List.from(_medicalRecord.backgroundDiseases);
        _medications = List.from(_medicalRecord.currentMedications);
      } else {
        _medicalRecord = MedicalRecord(id: _profile.id);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ensureVerified(VoidCallback onSuccess) async {
    if (!_profile.isVerified) {
      if (mounted) VerificationGuardDialog.show(context);
      return;
    }
    onSuccess();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final updateData = {
        'fullName': _nameController.text,
        'phone': _phoneController.text,
        'dateOfBirth': _dobController.text,
        'gender': _gender,
        'address': _addressController.text,
        'cccdNumber': _cccdController.text,
        'medicalRecord': {
          'bloodGroup': _bloodGroup,
          'distinguishingMarks': _marksController.text,
          'allergies': _allergies,
          'backgroundDiseases': _diseases,
          'currentMedications': _medications,
          'notes': _notesController.text,
        },
      };

      await AuthService.updateProfile(updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (!widget.showScaffold) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!widget.showScaffold) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildIdentityCard(),
                  const SizedBox(height: 16),
                  _buildMedicalInfoCard(),
                ],
              ),
            ),
          ),
          _buildBottomSave(),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hồ sơ người dùng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildTopTabs(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildIdentityCard(),
                  const SizedBox(height: 16),
                  _buildMedicalInfoCard(),
                ],
              ),
            ),
          ),
          _buildBottomSave(),
        ],
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context) {
    return Container(
      color: const Color(0xFFEDE1D3),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: const [
                SizedBox(height: 12),
                Text(
                  'Hồ sơ y tế',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                Divider(
                  thickness: 3,
                  height: 3,
                  color: AppColors.primaryOrange,
                  indent: 20,
                  endIndent: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmergencyContactsPage(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Thông tin người thân',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryBlack,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'Người dùng',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  // onTap: () => _ensureVerified(_updateFaceImage),
                  child: Container(
                    width: 100,
                    height: 128,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(10),
                      image: _profile.avatarUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_profile.avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profile.avatarUrl.isEmpty
                        ? const Icon(
                            PhosphorIconsRegular.userCircle,
                            size: 58,
                            color: Color(0xFFCFCFCF),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildIdentityRow('Số CCCD', _cccdController.text),
                      _buildIdentityRow('Ngày sinh', _dobController.text),
                      _buildIdentityRow('Giới tính', _gender),
                      _buildIdentityRow('Số điện thoại', _phoneController.text),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE6E6E6)),
          _buildQuickRow(
            PhosphorIconsRegular.faceMask,
            'Cập nhật khuôn mặt',
            onTap: () => _ensureVerified(_updateFaceImage),
          ),
          const Divider(height: 1, color: Color(0xFFE6E6E6)),
          _buildQuickRow(
            PhosphorIconsRegular.contactlessPayment,
            'Quản lý thẻ NFC',
            onTap: () => _ensureVerified(() {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NfcManagementPage()),
              );
            }),
          ),
          const Divider(height: 1, color: Color(0xFFE6E6E6)),
          _buildQuickRow(
            PhosphorIconsRegular.qrCode,
            'Mã QR của bạn',
            onTap: () => _ensureVerified(() {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QRManagementPage()),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa cập nhật',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRow(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlack, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              color: Color(0xFFA8A8A8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin y tế',
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          _buildMedicalLine(
            title: 'Nhóm máu',
            valueWidget: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _bloodGroup,
                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _bloodGroup = val!),
              ),
            ),
          ),
          _buildMedicalLine(
            title: 'Thông tin Dị ứng',
            value: _allergies.isEmpty ? 'Không có' : _allergies.join(', '),
            onTap: _showAllergyBottomSheet,
          ),
          _buildMedicalLine(
            title: 'Đơn thuốc đang dùng',
            value: _medications.isEmpty ? 'Không có' : _medications.join(', '),
            onTap: _showMedicationBottomSheet,
          ),
          _buildMedicalLine(
            title: 'Tình trạng bệnh lý',
            value: _diseases.isEmpty ? 'Không có' : _diseases.join(', '),
            onTap: _showDiseaseBottomSheet,
          ),
          const SizedBox(height: 12),
          const Text(
            'Thông tin khác',
            style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLength: 200,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '...',
              filled: true,
              fillColor: Color(0xFFF8F8F8),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalLine({
    required String title,
    String? value,
    Widget? valueWidget,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child:
                      valueWidget ??
                      Text(
                        value ?? '',
                        style: const TextStyle(
                          color: AppColors.primaryBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
                const Icon(
                  PhosphorIconsRegular.caretDown,
                  size: 18,
                  color: Color(0xFFB0B0B0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAllergyBottomSheet() async {
    final selected = <String>{};
    String otherAllergy = '';

    for (final item in _allergies) {
      if (item.startsWith('Khác: ')) {
        otherAllergy = item.replaceFirst('Khác: ', '');
      } else {
        selected.add(item);
      }
    }

    bool noneSelected = _allergies.isEmpty;
    final otherController = TextEditingController(text: otherAllergy);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildCheckItem(String label) {
              final checked = selected.contains(label);
              return InkWell(
                onTap: () {
                  setModalState(() {
                    if (checked) {
                      selected.remove(label);
                    } else {
                      selected.add(label);
                      noneSelected = false;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: checked
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF9B9B9B),
                            width: 2,
                          ),
                        ),
                        child: checked
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget buildGroup(String title, List<String> items) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...items.map(buildCheckItem),
                  ],
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2E7DB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Thông tin Dị ứng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                final updated = <String>[
                                  ...selected,
                                  if (otherController.text.trim().isNotEmpty)
                                    'Khác: ${otherController.text.trim()}',
                                ];
                                _allergies = noneSelected ? [] : updated;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                'Xong',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                'Bạn có mắc phải một hoặc nhiều loại dị ứng dưới đây không?',
                                style: TextStyle(
                                  color: AppColors.primaryBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    noneSelected = !noneSelected;
                                    if (noneSelected) {
                                      selected.clear();
                                      otherController.clear();
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: noneSelected
                                            ? const Color(0xFF10B981)
                                            : Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFF9B9B9B),
                                          width: 2,
                                        ),
                                      ),
                                      child: noneSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Không có',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.primaryBlack,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            buildGroup('Các loại thuốc', _drugAllergyOptions),
                            buildGroup('Thực phẩm', _foodAllergyOptions),
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextField(
                                controller: otherController,
                                maxLength: 200,
                                maxLines: 2,
                                onTap: () {
                                  if (noneSelected) {
                                    setModalState(() => noneSelected = false);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Thông tin dị ứng khác',
                                  hintText: '...',
                                  filled: true,
                                  fillColor: Color(0xFFF8F8F8),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showMedicationBottomSheet() async {
    final selected = <String>{..._medications};
    final otherController = TextEditingController();
    bool noneSelected = _medications.isEmpty;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildCheckItem(String label) {
              final checked = selected.contains(label);
              return InkWell(
                onTap: () {
                  setModalState(() {
                    if (checked) {
                      selected.remove(label);
                    } else {
                      selected.add(label);
                      noneSelected = false;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: checked
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF9B9B9B),
                            width: 2,
                          ),
                        ),
                        child: checked
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2E7DB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Đơn thuốc đang dùng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                final updated = <String>[
                                  ...selected,
                                  if (otherController.text.trim().isNotEmpty)
                                    'Khác: ${otherController.text.trim()}',
                                ];
                                _medications = noneSelected ? [] : updated;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                'Xong',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                'Bạn đang sử dụng loại thuốc nào dưới đây?',
                                style: TextStyle(
                                  color: AppColors.primaryBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    noneSelected = !noneSelected;
                                    if (noneSelected) {
                                      selected.clear();
                                      otherController.clear();
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: noneSelected
                                            ? const Color(0xFF10B981)
                                            : Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFF9B9B9B),
                                          width: 2,
                                        ),
                                      ),
                                      child: noneSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Không có',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.primaryBlack,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nhóm thuốc phổ biến',
                                    style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ..._medicationOptions.map(buildCheckItem),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextField(
                                controller: otherController,
                                maxLength: 200,
                                maxLines: 2,
                                onTap: () {
                                  if (noneSelected) {
                                    setModalState(() => noneSelected = false);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Thuốc khác',
                                  hintText: '...',
                                  filled: true,
                                  fillColor: Color(0xFFF8F8F8),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDiseaseBottomSheet() async {
    final selected = <String>{..._diseases};
    final otherController = TextEditingController();
    bool noneSelected = _diseases.isEmpty;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildCheckItem(String label) {
              final checked = selected.contains(label);
              return InkWell(
                onTap: () {
                  setModalState(() {
                    if (checked) {
                      selected.remove(label);
                    } else {
                      selected.add(label);
                      noneSelected = false;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: checked
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF9B9B9B),
                            width: 2,
                          ),
                        ),
                        child: checked
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2E7DB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tình trạng bệnh lý',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                final updated = <String>[
                                  ...selected,
                                  if (otherController.text.trim().isNotEmpty)
                                    'Khác: ${otherController.text.trim()}',
                                ];
                                _diseases = noneSelected ? [] : updated;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                'Xong',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                'Bạn đang có tình trạng bệnh lý nào dưới đây?',
                                style: TextStyle(
                                  color: AppColors.primaryBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    noneSelected = !noneSelected;
                                    if (noneSelected) {
                                      selected.clear();
                                      otherController.clear();
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: noneSelected
                                            ? const Color(0xFF10B981)
                                            : Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFF9B9B9B),
                                          width: 2,
                                        ),
                                      ),
                                      child: noneSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Không có',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.primaryBlack,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Danh mục bệnh lý',
                                    style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ..._diseaseOptions.map(buildCheckItem),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextField(
                                controller: otherController,
                                maxLength: 200,
                                maxLines: 2,
                                onTap: () {
                                  if (noneSelected) {
                                    setModalState(() => noneSelected = false);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Bệnh lý khác',
                                  hintText: '...',
                                  filled: true,
                                  fillColor: Color(0xFFF8F8F8),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSave() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cập nhật hồ sơ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateFaceImage() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FaceEnrollmentPage(
          onFaceCaptured: (path) async {
            final bytes = await File(path).readAsBytes();
            final b64 = base64Encode(bytes);

            setState(() => _isLoading = true);
            try {
              await AuthService.updateProfile({'faceImageB64': b64});
              await _fetchData(); // Refresh profile
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật ảnh đại diện thành công'),
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
              }
            } finally {
              setState(() => _isLoading = false);
            }
          },
        ),
      ),
    );
  }
}
