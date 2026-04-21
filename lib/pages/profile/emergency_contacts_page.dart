import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/pages/profile/medical_record_page.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/shared/models/contact_info.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key, this.showScaffold = true});
  final bool showScaffold;

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<ContactInfo> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      // 1. Tải profile mới nhất từ Read-Service để đảm bảo đồng bộ
      await AuthService.fetchAndCacheProfile();
      
      // 2. Đọc từ cache đã được cập nhật
      final profile = await AuthService.getCachedProfile();
      if (profile != null && profile['citizen'] != null) {
        final c = CitizenProfile.fromJson(profile['citizen']);
        setState(() {
          _contacts = List.from(c.emergencyContacts);
        });
      }
    } catch (e) {
      debugPrint("Error loading contacts: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.updateProfile({
        'emergencyContacts': _contacts.map((e) => e.toJson()).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật danh sách người thân')),
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

  void _showAddEditDialog([ContactInfo? contact, int? index]) {
    final nameController = TextEditingController(text: contact?.name);
    final relationController = TextEditingController(text: contact?.relationship);
    final phoneController = TextEditingController(text: contact?.phone);
    final backupPhoneController =
        TextEditingController(text: contact?.backupPhone);
    final emailController = TextEditingController(text: contact?.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30,
          left: 24,
          right: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index == null ? 'Thêm người thân' : 'Sửa thông tin',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildField('Họ và tên', nameController, PhosphorIconsRegular.user),
              _buildField('Mối quan hệ', relationController, PhosphorIconsRegular.usersThree),
              _buildField('Số điện thoại', phoneController, PhosphorIconsRegular.phone),
              _buildField('Số điện thoại dự phòng', backupPhoneController,
                  PhosphorIconsRegular.phonePlus),
              _buildField('Email', emailController, PhosphorIconsRegular.envelope),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final newContact = ContactInfo(
                      name: nameController.text,
                      relationship: relationController.text,
                      phone: phoneController.text,
                      backupPhone: backupPhoneController.text,
                      email: emailController.text,
                    );
                    setState(() {
                      if (index == null) {
                        _contacts.add(newContact);
                      } else {
                        _contacts[index] = newContact;
                      }
                    });
                    Navigator.pop(context);
                    _save();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Lưu thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryOrange, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showScaffold) {
      return Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final c = _contacts[index];
                          return _buildContactCard(c, index);
                        },
                      ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _showAddEditDialog,
              backgroundColor: const Color(0xFF10B981),
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
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
          onPressed: () => Navigator.pop(context),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final c = _contacts[index];
                          return _buildContactCard(c, index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditDialog,
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(PhosphorIconsRegular.plus, color: Colors.white, size: 32),
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
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MedicalRecordPage()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Hồ sơ y tế',
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
          Expanded(
            child: Column(
              children: const [
                SizedBox(height: 12),
                Text(
                  'Thông tin người thân',
                  textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.usersThree, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Chưa có thông tin người thân',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ContactInfo c, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '#${index + 1}. ${c.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showAddEditDialog(c, index),
                  child: const Icon(
                    PhosphorIconsRegular.pencilSimple,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                _buildDetailLine('Quan hệ với người dùng', c.relationship, withCaret: true),
                _buildDetailLine('Số điện thoại', c.phone, withEdit: true),
                _buildDetailLine(
                  'Số điện thoại dự phòng',
                  c.backupPhone.isNotEmpty ? c.backupPhone : 'Không có',
                  withEdit: true,
                ),
                _buildDetailLine('Nơi ở', c.email.isNotEmpty ? c.email : 'Không có', withEdit: true, isLast: true),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _contacts.removeAt(index));
                      _save();
                    },
                    icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: Colors.redAccent),
                    label: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailLine(
    String label,
    String value, {
    bool withEdit = false,
    bool withCaret = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (withCaret)
            const Icon(PhosphorIconsRegular.caretDown, size: 18, color: Color(0xFFB0B0B0)),
          if (withEdit)
            const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: Color(0xFFC0C0C0)),
        ],
      ),
    );
  }
}
