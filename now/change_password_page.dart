import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'profile_app_theme.dart';

class _Rule {
  final String label;
  final bool Function(String) test;

  const _Rule(this.label, this.test);
}

final List<_Rule> _passwordRules = [
  _Rule('อย่างน้อย 8 ตัวอักษร', (p) => p.length >= 8),
  _Rule(
    'มีตัวพิมพ์ใหญ่และตัวพิมพ์เล็ก (A-Z, a-z)',
    (p) => RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p),
  ),
  _Rule('มีตัวเลขอย่างน้อย 1 ตัว (0-9)', (p) => RegExp(r'[0-9]').hasMatch(p)),
  _Rule(
    r'มีอักขระพิเศษ (@, #, $, %, !)',
    (p) => RegExp(r'[^A-Za-z0-9]').hasMatch(p),
  ),
];

/// เปลี่ยนรหัสผ่าน (เรียก API changePassword)
/// เกณฑ์ที่บังคับจริงคือ 8-72 ตัวอักษร ส่วนตัววัดความแข็งแรงเป็นคำแนะนำ
/// สำเร็จแล้วปิดหน้ากลับไป (ไม่มีข้อมูลผู้ใช้เปลี่ยน)
class ChangePasswordPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChangePasswordPage({super.key, required this.user});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int get _score => _passwordRules.where((r) => r.test(_newCtrl.text)).length;

  String get _strengthLabel {
    switch (_score) {
      case 4:
        return 'แข็งแรงมาก';
      case 3:
        return 'ดี';
      case 2:
        return 'พอใช้';
      default:
        return 'อ่อน';
    }
  }

  Color get _strengthColor {
    switch (_score) {
      case 4:
        return kGreenDark;
      case 3:
        return const Color(0xFF65A30D);
      case 2:
        return const Color(0xFFF79009);
      default:
        return kError;
    }
  }

  Widget _eye(bool obscure, VoidCallback onTap) {
    return IconButton(
      tooltip: obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
      color: kIconMuted,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: onTap,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.changePassword(
        ApiService.userIdOf(widget.user),
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      showAppToast(context, 'เปลี่ยนรหัสผ่านสำเร็จ');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNew = _newCtrl.text.isNotEmpty;
    final hasConfirm = _confirmCtrl.text.isNotEmpty;
    final matches = _confirmCtrl.text == _newCtrl.text;

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('เปลี่ยนรหัสผ่าน'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthInfoCard(
                          icon: Icons.shield_outlined,
                          title: 'เพิ่มความปลอดภัยให้บัญชีของคุณ',
                          message:
                              'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร ยิ่งผสมตัวพิมพ์ใหญ่ พิมพ์เล็ก ตัวเลข และสัญลักษณ์พิเศษ ยิ่งปลอดภัย',
                        ),
                        const SizedBox(height: 24),

                        // ---- รหัสผ่านปัจจุบัน ----
                        AuthField(
                          label: 'รหัสผ่านปัจจุบัน',
                          required: true,
                          icon: Icons.key_outlined,
                          hint: 'กรอกรหัสผ่านปัจจุบัน',
                          controller: _currentCtrl,
                          obscureText: _obscureCurrent,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.password],
                          suffix: _eye(
                            _obscureCurrent,
                            () => setState(
                                () => _obscureCurrent = !_obscureCurrent),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'กรุณากรอกรหัสผ่านปัจจุบัน'
                              : null,
                        ),
                        const SizedBox(height: 18),

                        // ---- รหัสผ่านใหม่ ----
                        AuthField(
                          label: 'รหัสผ่านใหม่',
                          required: true,
                          icon: Icons.lock_outline,
                          hint: 'อย่างน้อย 8 ตัวอักษร',
                          controller: _newCtrl,
                          obscureText: _obscureNew,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => setState(() {}),
                          suffix: _eye(
                            _obscureNew,
                            () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'กรุณากรอกรหัสผ่านใหม่';
                            }
                            if (v.length < 8) {
                              return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                            }
                            if (utf8.encode(v).length > 72) {
                              return 'รหัสผ่านยาวเกินไป (ไม่เกิน 72 ไบต์)';
                            }
                            if (v == _currentCtrl.text) {
                              return 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม';
                            }
                            return null;
                          },
                        ),
                        if (hasNew) ...[
                          const SizedBox(height: 12),
                          _StrengthCard(
                            score: _score,
                            label: _strengthLabel,
                            color: _strengthColor,
                            password: _newCtrl.text,
                          ),
                        ],
                        const SizedBox(height: 18),

                        // ---- ยืนยันรหัสผ่านใหม่ ----
                        AuthField(
                          label: 'ยืนยันรหัสผ่านใหม่',
                          required: true,
                          icon: Icons.lock_reset_outlined,
                          hint: 'กรอกรหัสผ่านใหม่อีกครั้ง',
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _saving ? null : _save(),
                          suffix: _eye(
                            _obscureConfirm,
                            () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) =>
                              v != _newCtrl.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                        ),
                        if (hasConfirm) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                matches
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                size: 18,
                                color: matches ? kGreenDark : kError,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                matches ? 'รหัสผ่านตรงกัน' : 'รหัสผ่านไม่ตรงกัน',
                                style: TextStyle(
                                  color: matches ? kGreenDark : kError,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          BottomActionBar(
            label: 'อัปเดตรหัสผ่าน',
            icon: Icons.lock_outline,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// การ์ดแสดงระดับความปลอดภัย: แถบ 4 ช่อง + รายการเกณฑ์
class _StrengthCard extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  final String password;

  const _StrengthCard({
    required this.score,
    required this.label,
    required this.color,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E8F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ระดับความปลอดภัย:',
                  style: TextStyle(
                    color: kNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusChip(
                label: label,
                background: color.withAlpha(30),
                foreground: color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < score ? color : const Color(0xFFDDE3F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          for (final rule in _passwordRules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    rule.test(password)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: rule.test(password) ? kGreenDark : kIconMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rule.label,
                      style: TextStyle(
                        color: rule.test(password) ? kNavy : kMuted,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
