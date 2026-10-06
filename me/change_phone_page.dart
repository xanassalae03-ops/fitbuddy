import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'profile_app_theme.dart';

/// เปลี่ยน phone_number (เรียก API changePhone)
/// บันทึกสำเร็จจะ pop พร้อมข้อมูลผู้ใช้ที่อัปเดตแล้ว (Map) กลับไปหน้าตั้งค่า
class ChangePhonePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChangePhonePage({super.key, required this.user});

  @override
  State<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  String get _currentPhone =>
      (widget.user['phone_number'] ?? '').toString().trim();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final data = await ApiService.changePhone(
        ApiService.userIdOf(widget.user),
        _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      showAppToast(context, 'เปลี่ยนเบอร์โทรศัพท์สำเร็จ');
      Navigator.pop(context, <String, dynamic>{...widget.user, ...data});
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhone = _currentPhone;

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('เปลี่ยนเบอร์โทรศัพท์'),
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
                          icon: Icons.contact_phone_outlined,
                          title: 'เปลี่ยนเบอร์โทรศัพท์',
                          message:
                              'อัปเดตเบอร์โทรศัพท์ของบัญชีคุณ เบอร์ใหม่ต้องไม่ซ้ำกับผู้ใช้คนอื่น',
                        ),
                        const SizedBox(height: 16),

                        // ---- เบอร์ปัจจุบัน ----
                        Container(
                          padding: const EdgeInsets.all(16),
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: kPanel,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.phone_outlined,
                                  color: kIconMuted,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'เบอร์ปัจจุบัน',
                                      style: TextStyle(
                                        color: kMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentPhone.isEmpty ? '-' : currentPhone,
                                      style: const TextStyle(
                                        color: kNavy,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ---- เบอร์ใหม่ ----
                        AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthField(
                                label: 'เบอร์โทรศัพท์ใหม่',
                                required: true,
                                icon: Icons.phone_outlined,
                                hint: 'เช่น 0812345678',
                                onCard: true,
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                onChanged: (_) => setState(() {}),
                                onFieldSubmitted: (_) =>
                                    _saving ? null : _save(),
                                suffix: _phoneCtrl.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'ล้าง',
                                        color: kIconMuted,
                                        icon: const Icon(Icons.cancel_outlined),
                                        onPressed: () =>
                                            setState(_phoneCtrl.clear),
                                      ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) {
                                    return 'กรุณากรอกเบอร์โทรศัพท์ใหม่';
                                  }
                                  if (value.length < 9) {
                                    return 'เบอร์โทรศัพท์ต้องมี 9-10 หลัก';
                                  }
                                  if (value == currentPhone) {
                                    return 'เบอร์ใหม่ต้องไม่ซ้ำกับเบอร์ปัจจุบัน';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: kGreenDark,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'กรอกตัวเลข 9-10 หลักโดยไม่ต้องใส่ขีด',
                                      style: TextStyle(
                                        color: kMuted,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
          BottomActionBar(
            label: 'บันทึกเบอร์โทรศัพท์',
            icon: Icons.check_circle_outline,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
