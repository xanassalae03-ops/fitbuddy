import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'profile_app_theme.dart';

/// แก้ไข bio (เรียก API updateProfile) เว้นว่างเพื่อลบ bio ได้
/// บันทึกสำเร็จจะ pop พร้อมข้อมูลผู้ใช้ที่อัปเดตแล้ว (Map) กลับไปหน้าตั้งค่า
class EditBioPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditBioPage({super.key, required this.user});

  @override
  State<EditBioPage> createState() => _EditBioPageState();
}

class _EditBioPageState extends State<EditBioPage> {
  static const int _max = 150; // ตรงกับข้อจำกัดใน api.php

  late final TextEditingController _ctrl;
  late final String _original;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _original = (widget.user['bio'] ?? '').toString().trim();
    _ctrl = TextEditingController(text: _original);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final bio = _ctrl.text.trim();

    if (bio == _original) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      final data = await ApiService.updateProfile(
        ApiService.userIdOf(widget.user),
        bio: bio,
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
    final count = _ctrl.text.runes.length;

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('แก้ไขแนะนำตัว'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthInfoCard(
                        icon: Icons.edit_note_outlined,
                        title: 'แนะนำตัวเองสั้นๆ',
                        message:
                            'เล่าเกี่ยวกับตัวคุณให้เพื่อนร่วมก๊วนรู้จักมากขึ้น เช่น กีฬาที่ชอบหรือช่วงเวลาที่ว่าง',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'แนะนำตัวเองสั้นๆ (Bio)',
                              style: TextStyle(
                                color: kNavy,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '$count / $_max',
                            style: const TextStyle(
                              color: kMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ctrl,
                        minLines: 5,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        inputFormatters: [LengthLimitingTextInputFormatter(_max)],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: kNavy,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        cursorColor: kGreenDark,
                        decoration: authInputDecoration(
                          hint: 'เล่าเกี่ยวกับตัวคุณสั้นๆ',
                        ),
                      ),
                    ],
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
