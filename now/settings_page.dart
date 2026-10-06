import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'profile_app_theme.dart';
import 'change_password_page.dart';
import 'change_phone_page.dart';
import 'edit_bio_page.dart';
import 'edit_name_page.dart';

/// หน้า "ตั้งค่าบัญชี" (เปิดจากไอคอนฟันเฟืองในหน้าโปรไฟล์)
/// - กดปุ่ม "เปลี่ยน" เพื่อไปหน้าแก้ไขข้อมูลนั้น ๆ
/// - กดที่รูปโปรไฟล์เพื่อถ่ายรูป/เลือกรูปใหม่ (อัปโหลดแล้วเก็บเป็น avatar_url)
/// - ทุกครั้งที่ข้อมูลเปลี่ยน จะเรียก [onUserChanged] ให้หน้าโปรไฟล์อัปเดตตาม
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
  static const int _maxImageBytes = 2 * 1024 * 1024; // ตรงกับ api.php (2 MB)

  late Map<String, dynamic> _user;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
  }

  String _text(String key) => (_user[key] ?? '').toString().trim();

  String get _fullName => _text('full_name');
  String get _nickname => _text('nickname');
  String get _phone => _text('phone_number');
  String get _email => _text('email');
  String get _bio => _text('bio');
  String get _avatarUrl => _text('avatar_url');

  /// "full_name (nickname)" — ถ้าไม่มี nickname จะแสดงแค่ full_name
  String get _displayName =>
      _nickname.isEmpty ? _fullName : '$_fullName ($_nickname)';

  bool get _isVerified {
    final v = _user['is_verified'];
    return v == true || v == 1 || v == '1';
  }

  /// trust_score แบบพร้อมแสดง (ไม่มีทศนิยมถ้าเป็นจำนวนเต็ม)
  String get _trustScore {
    final n = double.tryParse(_text('trust_score'));
    if (n == null) return '-';
    return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
  }

  void _apply(Map<String, dynamic> updated) {
    setState(() => _user = updated);
    widget.onUserChanged(updated);
  }

  /// เปิดหน้าแก้ไข ถ้าบันทึกสำเร็จหน้านั้นจะส่งข้อมูลผู้ใช้ใหม่กลับมา
  Future<void> _openEdit(Widget page) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (result != null && mounted) _apply(result);
  }

  // ------------------------------------------------------------------
  // เปลี่ยนรูปโปรไฟล์
  // ------------------------------------------------------------------

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE3F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'เปลี่ยนรูปโปรไฟล์',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                label: 'ถ่ายรูป',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'เลือกจากอัลบั้ม',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    if (_uploading) return;

    final source = await _chooseSource();
    if (source == null || !mounted) return;

    try {
      // ย่อรูปก่อนอัปโหลดเพื่อให้ไฟล์เล็กและเร็วขึ้น
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return; // ผู้ใช้ยกเลิก

      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxImageBytes) {
        if (mounted) {
          showAppToast(context, 'รูปใหญ่เกินไป (ไม่เกิน 2 MB)', error: true);
        }
        return;
      }

      if (mounted) setState(() => _uploading = true);
      final data = await ApiService.uploadAvatar(
        ApiService.userIdOf(_user),
        bytes: bytes,
        filename: picked.name,
      );
      if (!mounted) return;
      _apply(<String, dynamic>{..._user, ...data});
      showAppToast(context, 'อัปเดตรูปโปรไฟล์สำเร็จ');
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          'เลือกรูปไม่สำเร็จ ตรวจสอบสิทธิ์เข้าถึงรูปภาพ/กล้อง',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ------------------------------------------------------------------

  Widget _buildAvatar() {
    return Semantics(
      button: true,
      label: 'เปลี่ยนรูปโปรไฟล์',
      child: GestureDetector(
        onTap: _changeAvatar,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(url: _avatarUrl, size: 64),
              if (_uploading)
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: const Color(0x66000000),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              // ป้ายกล้องมุมขวาล่าง
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: kGreenDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('ตั้งค่าบัญชี'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- ป้ายหัวข้อ ----
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FITBUDDY SETTINGS',
                        style: TextStyle(
                          color: kGreenDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ---- สรุปโปรไฟล์ (กดที่รูปเพื่อเปลี่ยนรูป) ----
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kPanelBorder),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPanel, Color(0xFFE3FAEF)],
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName,
                                style: const TextStyle(
                                  color: kNavy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (_isVerified)
                                    const StatusChip(
                                      label: 'ยืนยันแล้ว',
                                      icon: Icons.verified,
                                    ),
                                  StatusChip(
                                    label: 'Trust Score $_trustScore',
                                    icon: Icons.shield_outlined,
                                    background: Colors.white,
                                    foreground: kNavy,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- ข้อมูลส่วนตัว ----
                  const SectionTitle(
                    icon: Icons.badge_outlined,
                    title: 'ข้อมูลส่วนตัว',
                    trailing: 'แก้ไขได้ตลอดเวลา',
                  ),
                  const SizedBox(height: 12),
                  AuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldRow(
                          label: 'ชื่อ - นามสกุล',
                          icon: Icons.person_outline,
                          value: _fullName,
                          actionLabel: 'เปลี่ยน',
                          onAction: () => _openEdit(EditNamePage(user: _user)),
                        ),
                        const SizedBox(height: 16),
                        _FieldRow(
                          label: 'ชื่อเล่นในแอป',
                          icon: Icons.mood_outlined,
                          value: _nickname,
                          actionLabel: 'เปลี่ยน',
                          onAction: () => _openEdit(EditNamePage(user: _user)),
                        ),
                        const SizedBox(height: 16),
                        _FieldRow(
                          label: 'เบอร์โทรศัพท์มือถือ',
                          icon: Icons.phone_outlined,
                          value: _phone,
                          actionLabel: 'เปลี่ยนเบอร์',
                          onAction: () =>
                              _openEdit(ChangePhonePage(user: _user)),
                        ),
                        const SizedBox(height: 16),
                        _FieldRow(
                          label: 'อีเมล',
                          icon: Icons.mail_outline,
                          value: _email,
                        ),
                        const SizedBox(height: 16),
                        _BioRow(
                          bio: _bio,
                          onAction: () => _openEdit(EditBioPage(user: _user)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- ความปลอดภัย ----
                  const SectionTitle(
                    icon: Icons.lock_outline,
                    title: 'ความปลอดภัย',
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.lock_reset_outlined,
                    label: 'เปลี่ยนรหัสผ่าน',
                    onTap: () => _openEdit(ChangePasswordPage(user: _user)),
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

// =====================================================================
// วิดเจ็ตย่อยของหน้านี้
// =====================================================================

/// ตัวเลือกใน bottom sheet เลือกแหล่งรูป
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: kMint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: kGreenDark),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: kNavy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// ปุ่มเล็ก "เปลี่ยน" สีฟ้าอ่อน
class _ChangeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ChangeButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: const TextStyle(
              color: kNavy,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// ช่องแสดงข้อมูล 1 บรรทัด พร้อมปุ่ม "เปลี่ยน" ถ้ามี
class _FieldRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FieldRow({
    required this.label,
    required this.icon,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kNavy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: kFieldTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E8F4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: kIconMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(color: kNavy, fontSize: 16),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                _ChangeButton(label: actionLabel!, onTap: onAction),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Bio: ป้ายชื่อ + ปุ่มเปลี่ยนด้านขวา และกล่องข้อความหลายบรรทัด
class _BioRow extends StatelessWidget {
  final String bio;
  final VoidCallback onAction;

  const _BioRow({required this.bio, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'แนะนำตัวเองสั้นๆ (Bio)',
                style: TextStyle(
                  color: kNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ChangeButton(label: 'เปลี่ยน', onTap: onAction),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: kFieldTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E8F4)),
          ),
          child: Text(
            bio.isEmpty ? 'ยังไม่ได้เขียนแนะนำตัว' : bio,
            style: TextStyle(
              color: bio.isEmpty ? kMuted : kNavy,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// แถวเมนูกดได้ (การ์ดสีขาว + ลูกศรท้ายแถว)
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kMint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: kGreenDark, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: kNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: kIconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
