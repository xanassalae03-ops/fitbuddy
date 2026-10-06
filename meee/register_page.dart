import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'constants.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _pdpaAccepted = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_pdpaAccepted) {
      showAppToast(context, 'กรุณายอมรับนโยบายข้อมูลส่วนบุคคล (PDPA)', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.register(
        fullName: _fullNameCtrl.text,
        nickname: _nicknameCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      showAppToast(context, 'สมัครสมาชิกสำเร็จ เข้าสู่ระบบได้เลย');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('สร้างบัญชี'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AuthField(label: 'ชื่อ-นามสกุล', controller: _fullNameCtrl, icon: Icons.badge_outlined, required: true),
                const SizedBox(height: 16),
                AuthField(label: 'ชื่อเล่น', controller: _nicknameCtrl, icon: Icons.person_outline, required: true),
                const SizedBox(height: 16),
                AuthField(
                  label: 'เบอร์โทรศัพท์',
                  controller: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  required: true,
                ),
                const SizedBox(height: 16),
                AuthField(label: 'อีเมล', controller: _emailCtrl, icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, required: true),
                const SizedBox(height: 16),
                AuthField(label: 'รหัสผ่าน', controller: _passwordCtrl, icon: Icons.lock_outline, obscureText: true, required: true),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: _pdpaAccepted,
                  onChanged: (v) => setState(() => _pdpaAccepted = v ?? false),
                  title: const Text('ฉันยินยอมให้เก็บข้อมูลตาม PDPA', style: TextStyle(color: kNavy, fontSize: 14)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(label: 'สมัครสมาชิก', loading: _loading, onPressed: _register),
              ],
            ),
          ),
        ),
      ),
    );
  }
}