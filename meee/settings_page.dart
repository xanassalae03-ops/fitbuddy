import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'constants.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onUserChanged;

  const SettingsPage({
    super.key,
    required this.user,
    required this.onUserChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Map<String, dynamic> _user;
  final _fullNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
    _fullNameCtrl.text = (_user['full_name'] ?? '').toString();
    _nicknameCtrl.text = (_user['nickname'] ?? '').toString();
    _bioCtrl.text = (_user['bio'] ?? '').toString();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateProfile(
        userIdOf(_user),
        fullName: _fullNameCtrl.text,
        nickname: _nicknameCtrl.text,
        bio: _bioCtrl.text,
      );
      if (!mounted) return;
      setState(() => _user = updated);
      widget.onUserChanged(updated);
      showAppToast(context, 'บันทึกข้อมูลเรียบร้อย');
      Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('ตั้งค่าโปรไฟล์'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AuthCard(
                child: Column(
                  children: [
                    AuthField(
                      label: 'ชื่อ-นามสกุล',
                      controller: _fullNameCtrl,
                      icon: Icons.badge_outlined,
                      onCard: true,
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      label: 'ชื่อเล่น',
                      controller: _nicknameCtrl,
                      icon: Icons.person_outline,
                      onCard: true,
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      label: 'แนะนำตัวเอง (Bio)',
                      controller: _bioCtrl,
                      icon: Icons.notes_outlined,
                      onCard: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'บันทึกข้อมูล',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}