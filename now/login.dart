import 'package:flutter/material.dart';

import 'api_service.dart';
import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

// ==========================================
// LOGIN
// ==========================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ApiService.login(_email.text, _password.text);
      Session.user = user;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegister() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (email != null && mounted) {
      setState(() => _email.text = email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kInk,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: kLime, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'FitBuddy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'หาเพื่อนออกกำลังกาย แล้วไปเล่นด้วยกัน',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: _dec('อีเมล', Icons.mail_outline),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'กรุณากรอกอีเมล' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _loading ? null : _submit(),
                      decoration: _dec('รหัสผ่าน', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: kBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('เข้าสู่ระบบ',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : _openRegister,
                      child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _dec(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );

// ==========================================
// REGISTER
// ==========================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _nickname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _consent = false;
  bool _loading = false;

  @override
  void dispose() {
    _fullName.dispose();
    _nickname.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      showSnack(context, 'กรุณายอมรับนโยบายข้อมูลส่วนบุคคล (PDPA)', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.register(
        fullName: _fullName.text,
        nickname: _nickname.text,
        phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      showSnack(context, 'สมัครสมาชิกสำเร็จ เข้าสู่ระบบได้เลย');
      Navigator.of(context).pop(_email.text.trim());
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        backgroundColor: kSurface,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullName,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('ชื่อ-นามสกุล', Icons.badge_outlined),
                      validator: (v) {
                        if (_required(v, 'กรุณากรอกชื่อ-นามสกุล') != null) {
                          return 'กรุณากรอกชื่อ-นามสกุล';
                        }
                        return v!.trim().length > 100 ? 'ไม่เกิน 100 ตัวอักษร' : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nickname,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('ชื่อเล่น', Icons.person_outline),
                      validator: (v) {
                        if (_required(v, 'กรุณากรอกชื่อเล่น') != null) {
                          return 'กรุณากรอกชื่อเล่น';
                        }
                        return v!.trim().length > 50 ? 'ไม่เกิน 50 ตัวอักษร' : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('เบอร์โทรศัพท์', Icons.phone_outlined),
                      validator: (v) {
                        final p = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                        if (p.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
                        return RegExp(r'^\+?[0-9]{9,15}$').hasMatch(p)
                            ? null
                            : 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('อีเมล', Icons.mail_outline),
                      validator: (v) {
                        final e = (v ?? '').trim();
                        if (e.isEmpty) return 'กรุณากรอกอีเมล';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)
                            ? null
                            : 'รูปแบบอีเมลไม่ถูกต้อง';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('รหัสผ่าน (อย่างน้อย 8 ตัว)', Icons.lock_outline),
                      validator: (v) {
                        final p = v ?? '';
                        if (p.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                        if (p.length > 72) return 'รหัสผ่านต้องไม่เกิน 72 ตัวอักษร';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: _dec('ยืนยันรหัสผ่าน', Icons.lock_reset),
                      validator: (v) =>
                          v == _password.text ? null : 'รหัสผ่านไม่ตรงกัน',
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'ฉันยอมรับนโยบายข้อมูลส่วนบุคคล (PDPA)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: kBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('สมัครสมาชิก',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
