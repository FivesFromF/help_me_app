import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:help_me_app/app_colors.dart';
import 'package:help_me_app/shared/services/auth_service.dart';
import 'package:help_me_app/shared/models/contact_info.dart';
import 'package:help_me_app/shared/models/citizen_profile.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

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
      padding: const EdgeInsets.bottom(16),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thông tin người thân', style: TextStyle(color: AppColors.primaryBlack, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _contacts.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final c = _contacts[index];
                return _buildContactCard(c, index);
              },
            ),
      bottomNavigationBar: _buildBottomBtn(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.usersThree, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Chưa có thông tin người thân', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContactCard(ContactInfo c, int index) {
    return Container(
      margin: const EdgeInsets.bottom(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(color: AppColors.secondaryOrange, shape: BoxShape.circle),
                child: const Icon(PhosphorIconsRegular.user, color: AppColors.primaryOrange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(c.relationship, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 20, color: Colors.grey),
                onPressed: () => _showAddEditDialog(c, index),
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.trash, size: 20, color: Colors.redAccent),
                onPressed: () {
                   setState(() => _contacts.removeAt(index));
                   _save();
                },
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(PhosphorIconsRegular.phone, c.phone),
          const SizedBox(height: 8),
          _buildInfoRow(PhosphorIconsRegular.envelope, c.email),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text.isNotEmpty ? text : 'Chưa cập nhật', style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
      ],
    );
  }

  Widget _buildBottomBtn() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF5F5F5)))),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(PhosphorIconsRegular.plus, size: 20),
          label: const Text('Thêm người thân', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
