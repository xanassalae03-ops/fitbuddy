import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'home_shell.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = await ApiService.login(_emailCtrl.text, _passwordCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeShell(user: user)),
      );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const AuthLogo(),
                  const SizedBox(height: 20),
                  const Text('FitBuddy', style: TextStyle(color: kNavy, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('หาเพื่อนออกกำลังกายใกล้คุณ', style: TextStyle(color: kMuted, fontSize: 15)),
                  const SizedBox(height: 28),
                  AuthCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AuthField(
                            label: 'อีเมล',
                            hint: 'กรอกอีเมลของคุณ',
                            icon: Icons.alternate_email,
                            onCard: true,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกอีเมล' : null,
                          ),
                          const SizedBox(height: 18),
                          AuthField(
                            label: 'รหัสผ่าน',
                            hint: 'กรอกรหัสผ่าน',
                            icon: Icons.lock_outline,
                            onCard: true,
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            suffix: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                          ),
                          const SizedBox(height: 26),
                          AuthPrimaryButton(label: 'เข้าสู่ระบบ', loading: _loading, onPressed: _login),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ยังไม่มีบัญชี?', style: TextStyle(color: kMuted)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text('สมัครสมาชิก', style: TextStyle(color: kGreenDark, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}