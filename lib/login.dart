import 'package:flutter/material.dart';

import 'api_service.dart';
import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

// ==========================================
// THEME (สีเฉพาะหน้า Login / Register)
// ==========================================

const _kBg = kSurface;
const _kGreenDark = kInk;
const _kLabel = kInk;
const _kHint = kNeutral;
const _kIcon = kNeutral;
const _kNotice = Color(0xFFE0F2FE);

// ==========================================
// SHARED WIDGETS
// ==========================================

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kLabel,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: kDanger),
              ),
          ],
        ),
      ),
    );
  }
}

/// ช่องกรอกแบบมีเงานุ่ม ๆ ไม่มีขอบ
class _SoftField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _SoftField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: kInk),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 15, color: _kHint),
          prefixIcon: Icon(icon, color: _kIcon, size: 22),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kDanger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kDanger, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// ปุ่มสีเขียวสดตามดีไซน์
class _GreenButton extends StatelessWidget {
  final String label;
  final IconData? trailing;
  final bool loading;
  final VoidCallback? onPressed;

  const _GreenButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kGreen.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kGreen,
          disabledBackgroundColor: kGreen.withOpacity(0.6),
          foregroundColor: kInk,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: kInk),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailing, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  final double size;
  const _LogoBox({this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: kGreen.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kGreen, kBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.18),
          ),
          child: Icon(Icons.bolt_rounded,
              color: kInk, size: size * 0.4),
        ),
      ),
    );
  }
}

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
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _LogoBox(size: 80)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'FitBuddy',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'TH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _kGreenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'หาเพื่อนออกกำลังกาย แล้วไปเล่นด้วยกัน',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _kHint, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // ---------- การ์ดฟอร์ม ----------
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: kInk.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _FieldLabel('อีเมล'),
                          _SoftField(
                            controller: _email,
                            hint: 'เช่น nut@fitbuddy.com',
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกอีเมล'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          const _FieldLabel('รหัสผ่าน'),
                          _SoftField(
                            controller: _password,
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _loading ? null : _submit(),
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _kIcon,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'กรุณากรอกรหัสผ่าน'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          _GreenButton(
                            label: 'เข้าสู่ระบบ (Log In)',
                            trailing: Icons.arrow_forward,
                            loading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.grey.shade200, height: 1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------- สมัครสมาชิก ----------
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'ยังไม่มีบัญชี FitBuddy? ',
                        style: TextStyle(color: _kHint, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: _loading ? null : _openRegister,
                        child: const Text(
                          'สมัครสมาชิกใหม่เลย',
                          style: TextStyle(
                            color: _kGreenDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---------- ประกาศความปลอดภัย ----------
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kNotice,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: _kGreenDark, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ข้อมูลของคุณได้รับการปกป้องตามมาตรฐานความปลอดภัยและความเป็นส่วนตัวสูงสุด',
                            style: TextStyle(
                                fontSize: 12.5, color: _kLabel, height: 1.4),
                          ),
                        ),
                      ],
                    ),
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
  bool _obscurePw = true;
  bool _obscureConfirm = true;

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

  Widget _eye(bool obscured, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: _kIcon,
        ),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: kGreen, size: 22),
            SizedBox(width: 6),
            Text(
              'FitBuddy',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------- ป้ายชุมชน ----------
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF6EC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: kGreen),
                            SizedBox(width: 6),
                            Text(
                              'คอมมูนิตี้คนออกกำลังกายอันดับ 1',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kGreenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Flexible(
                          child: Text(
                            'สร้างบัญชีก๊วน FitBuddy',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.directions_run_rounded,
                            color: Color(0xFFFFA000), size: 26),
                        Icon(Icons.bolt_rounded,
                            color: Color(0xFFFF7043), size: 26),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ---------- ชื่อ-นามสกุล ----------
                    const _FieldLabel('ชื่อ-นามสกุล', required: true),
                    _SoftField(
                      controller: _fullName,
                      hint: 'เช่น ภาณุวัฒน์ สุขใจ',
                      icon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (_required(v, 'กรุณากรอกชื่อ-นามสกุล') != null) {
                          return 'กรุณากรอกชื่อ-นามสกุล';
                        }
                        return v!.trim().length > 100
                            ? 'ไม่เกิน 100 ตัวอักษร'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ---------- ชื่อเล่น ----------
                    const _FieldLabel('ชื่อเล่น', required: true),
                    _SoftField(
                      controller: _nickname,
                      hint: 'เช่น นัท',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (_required(v, 'กรุณากรอกชื่อเล่น') != null) {
                          return 'กรุณากรอกชื่อเล่น';
                        }
                        return v!.trim().length > 50
                            ? 'ไม่เกิน 50 ตัวอักษร'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ---------- เบอร์โทร ----------
                    const _FieldLabel('เบอร์โทรศัพท์', required: true),
                    _SoftField(
                      controller: _phone,
                      hint: 'เช่น 081-234-5678',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final p = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                        if (p.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
                        return RegExp(r'^\+?[0-9]{9,15}$').hasMatch(p)
                            ? null
                            : 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
                      },
                    ),
                    const SizedBox(height: 16),

                    // ---------- อีเมล ----------
                    const _FieldLabel('อีเมล', required: true),
                    _SoftField(
                      controller: _email,
                      hint: 'เช่น nut.fitbuddy@gmail.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final e = (v ?? '').trim();
                        if (e.isEmpty) return 'กรุณากรอกอีเมล';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)
                            ? null
                            : 'รูปแบบอีเมลไม่ถูกต้อง';
                      },
                    ),
                    const SizedBox(height: 16),

                    // ---------- รหัสผ่าน ----------
                    const _FieldLabel('รหัสผ่าน', required: true),
                    _SoftField(
                      controller: _password,
                      hint: 'ความยาวอย่างน้อย 8 ตัวอักษร',
                      icon: Icons.lock_outline,
                      obscure: _obscurePw,
                      textInputAction: TextInputAction.next,
                      suffix: _eye(_obscurePw,
                          () => setState(() => _obscurePw = !_obscurePw)),
                      validator: (v) {
                        final p = v ?? '';
                        if (p.length < 8) {
                          return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                        }
                        if (p.length > 72) {
                          return 'รหัสผ่านต้องไม่เกิน 72 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ---------- ยืนยันรหัสผ่าน ----------
                    const _FieldLabel('ยืนยันรหัสผ่าน', required: true),
                    _SoftField(
                      controller: _confirm,
                      hint: 'กรอกรหัสผ่านอีกครั้ง',
                      icon: Icons.verified_outlined,
                      obscure: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      suffix: _eye(
                          _obscureConfirm,
                          () => setState(
                              () => _obscureConfirm = !_obscureConfirm)),
                      validator: (v) =>
                          v == _password.text ? null : 'รหัสผ่านไม่ตรงกัน',
                    ),
                    const SizedBox(height: 20),

                    // ---------- PDPA ----------
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kNotice,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.15,
                            child: Checkbox(
                              value: _consent,
                              activeColor: kGreen,
                              checkColor: Colors.white,
                              side: const BorderSide(
                                  color: kGreen, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              onChanged: (v) =>
                                  setState(() => _consent = v ?? false),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _consent = !_consent),
                              child: const Text.rich(
                                TextSpan(
                                  text: 'ฉันยอมรับ ',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                      height: 1.4),
                                  children: [
                                    TextSpan(
                                      text: 'ข้อกำหนดการใช้งาน',
                                      style: TextStyle(
                                        color: _kGreenDark,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: ' และ '),
                                    TextSpan(
                                      text: 'นโยบายความเป็นส่วนตัว (PDPA)',
                                      style: TextStyle(
                                        color: _kGreenDark,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---------- ปุ่มสร้างบัญชี ----------
                    _GreenButton(
                      label: 'สร้างบัญชี',
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 16),

                    // ---------- กลับไปเข้าสู่ระบบ ----------
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'มีบัญชีอยู่แล้ว? ',
                          style: TextStyle(color: _kHint, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: _loading
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          child: const Text(
                            'เข้าสู่ระบบที่นี่',
                            style: TextStyle(
                              color: _kGreenDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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