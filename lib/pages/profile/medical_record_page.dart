import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';
import 'package:help_me_app/shared/models/medical_record.dart';

class MedicalRecordPage extends StatefulWidget {
  const MedicalRecordPage({super.key});

  @override
  State<MedicalRecordPage> createState() => _MedicalRecordPageState();
}

class _MedicalRecordPageState extends State<MedicalRecordPage> {
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
        _bloodGroup = _medicalRecord.bloodGroup.isNotEmpty ? _medicalRecord.bloodGroup : 'A+';
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
        }
      };

      await AuthService.updateProfile(updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.primaryBlack),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Hồ sơ y tế',
            style: TextStyle(color: AppColors.primaryBlack, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryOrange,
            unselectedLabelColor: Color(0xFF888888),
            indicatorColor: AppColors.primaryOrange,
            tabs: [
              Tab(text: 'Thông tin cá nhân'),
              Tab(text: 'Y tế'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                   _buildPersonalInfoTab(),
                   _buildMedicalInfoTab(),
                ],
              ),
            ),
            _buildBottomSave(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInputGroup('Họ và tên', _nameController, PhosphorIconsRegular.user),
          _buildInputGroup('Số điện thoại', _phoneController, PhosphorIconsRegular.phone),
          _buildInputGroup('Ngày sinh (YYYY-MM-DD)', _dobController, PhosphorIconsRegular.calendar),
          _buildGenderSelector(),
          _buildInputGroup('Địa chỉ', _addressController, PhosphorIconsRegular.mapPin),
          _buildInputGroup('Số CCCD', _cccdController, PhosphorIconsRegular.identificationCard),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBloodGroupDropdown(),
          _buildInputGroup('Đặc điểm nhận dạng', _marksController, PhosphorIconsRegular.fingerprint),
          
          _buildDynamicList('Dị ứng', _allergies, (val) => setState(() => _allergies.add(val)), (idx) => setState(() => _allergies.removeAt(idx))),
          _buildDynamicList('Bệnh nền', _diseases, (val) => setState(() => _diseases.add(val)), (idx) => setState(() => _diseases.removeAt(idx))),
          _buildDynamicList('Thuốc đang dùng', _medications, (val) => setState(() => _medications.add(val)), (idx) => setState(() => _medications.removeAt(idx))),
          
          _buildInputGroup('Ghi chú thêm', _notesController, PhosphorIconsRegular.note, isLongText: true),
        ],
      ),
    );
  }

  Widget _buildInputGroup(String label, TextEditingController controller, IconData icon, {bool isLongText = false}) {
    return Container(
      margin: const EdgeInsets.bottom(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: isLongText ? 3 : 1,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryOrange),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      margin: const EdgeInsets.bottom(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderBtn('Nam'),
              const SizedBox(width: 12),
              _genderBtn('Nữ'),
              const SizedBox(width: 12),
              _genderBtn('Khác'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderBtn(String g) {
    final isSelected = _gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = g),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryOrange : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primaryOrange : const Color(0xFFEEEEEE)),
          ),
          child: Center(
            child: Text(
              g,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primaryBlack,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Container(
      margin: const EdgeInsets.bottom(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhóm máu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _bloodGroup,
                isExpanded: true,
                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (val) => setState(() => _bloodGroup = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicList(String title, List<String> items, Function(String) onAdd, Function(int) onRemove) {
    return Container(
      margin: const EdgeInsets.bottom(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
               IconButton(
                 icon: const Icon(PhosphorIconsRegular.plusCircle, color: AppColors.primaryOrange),
                 onPressed: () => _showAddDialog(title, onAdd),
               ),
            ],
          ),
          if (items.isEmpty)
             const Text('Chưa có thông tin', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
          Wrap(
            spacing: 8,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.secondaryOrange,
                deleteIcon: const Icon(PhosphorIconsRegular.x, size: 14),
                onDeleted: () => onRemove(entry.key),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(String title, Function(String) onAdd) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm $title'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập nội dung...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                onAdd(textController.text);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSave() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
