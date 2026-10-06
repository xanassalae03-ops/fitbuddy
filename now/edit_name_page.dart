import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'profile_app_theme.dart';

/// แก้ไข full_name และ nickname (เรียก API updateProfile)
/// บันทึกสำเร็จจะ pop พร้อมข้อมูลผู้ใช้ที่อัปเดตแล้ว (Map) กลับไปหน้าตั้งค่า
class EditNamePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditNamePage({super.key, required this.user});

  @override
  State<EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends State<EditNamePage> {
  static const int _fullNameMax = 100; // ตรงกับข้อจำกัดใน api.php
  static const int _nicknameMax = 50;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _nicknameCtrl;
  bool _saving = false;

  String _field(String key) => (widget.user[key] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: _field('full_name'));
    _nicknameCtrl = TextEditingController(text: _field('nickname'));
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  String _counter(TextEditingController c, int max) =>
      '${c.text.runes.length} / $max';

  Widget _clearButton(TextEditingController c) {
    if (c.text.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'ล้าง',
      color: kIconMuted,
      icon: const Icon(Icons.cancel_outlined),
      onPressed: () => setState(c.clear),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final fullName = _fullNameCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();

    // ไม่มีอะไรเปลี่ยน ปิดหน้าได้เลย
    if (fullName == _field('full_name') && nickname == _field('nickname')) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      final data = await ApiService.updateProfile(
        ApiService.userIdOf(widget.user),
        fullName: fullName,
        nickname: nickname,
      );
      if (!mounted) return;
      showAppToast(context, 'บันทึกข้อมูลสำเร็จ');
      Navigator.pop(context, <String, dynamic>{...widget.user, ...data});
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _nicknameCtrl.text.trim();
    final previewName =
        nickname.isNotEmpty ? nickname : _fullNameCtrl.text.trim();

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('แก้ไขชื่อ'),
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
                          title: 'ข้อมูลส่วนบุคคล',
                          message:
                              'ชื่อ-นามสกุลเป็นข้อมูลของบัญชีคุณ ส่วนชื่อเล่นจะแสดงให้เพื่อนร่วมก๊วนเห็นในแชท',
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'ตัวอย่างที่เพื่อนร่วมก๊วนจะเห็นในแชท',
                          style: TextStyle(
                            color: kMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x100F1E3C),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                url: _field('avatar_url'),
                                size: 52,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  previewName.isEmpty ? '-' : previewName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: kNavy,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthField(
                          label: 'ชื่อ-นามสกุลจริง',
                          required: true,
                          icon: Icons.badge_outlined,
                          hint: 'กรอกชื่อ-นามสกุล',
                          controller: _fullNameCtrl,
                          counter: _counter(_fullNameCtrl, _fullNameMax),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_fullNameMax),
                          ],
                          onChanged: (_) => setState(() {}),
                          suffix: _clearButton(_fullNameCtrl),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรุณากรอกชื่อ-นามสกุล'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        AuthField(
                          label: 'ชื่อเล่นในแอป',
                          required: true,
                          icon: Icons.mood_outlined,
                          hint: 'กรอกชื่อเล่น',
                          controller: _nicknameCtrl,
                          counter: _counter(_nicknameCtrl, _nicknameMax),
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.nickname],
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_nicknameMax),
                          ],
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _saving ? null : _save(),
                          suffix: _clearButton(_nicknameCtrl),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรุณากรอกชื่อเล่น'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          BottomActionBar(
            label: 'บันทึกข้อมูล',
            icon: Icons.save_outlined,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
