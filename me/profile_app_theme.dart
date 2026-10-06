import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart' as app;

/// ธีมกลางของ FitBuddy: สีและวิดเจ็ตที่ใช้ซ้ำในหน้า login / register
/// (หน้าอื่นที่จะแต่งต่อไปให้ import ไฟล์นี้ได้เลย)

// ---- พาเลตต์สี ----
const Color kNavy = app.kInk;
const Color kGreen = app.kGreen;
const Color kGreenDark = app.kInk;
const Color kBg = app.kSurface;
const Color kFieldTint = Color(0xFFF1F5F9);
const Color kPanel = Color(0xFFE0F2FE);
const Color kPanelBorder = Color(0xFFBAE6FD);
const Color kMint = Color(0xFFDCFCE7);
const Color kMuted = app.kNeutral;
const Color kIconMuted = app.kNeutral;
const Color kError = app.kDanger;

/// SnackBar กลาง
void showAppToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? kError : kNavy,
      ),
    );
}

/// โลโก้สี่เหลี่ยมมุมมนสีเขียว (ยังไม่มีไฟล์โลโก้จริง ใช้ไอคอนแทนไปก่อน)
class AuthLogo extends StatelessWidget {
  final double size;
  final bool glow;

  const AuthLogo({super.key, this.size = 72, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: glow
            ? const [
                BoxShadow(
                  color: Color(0x6600DC82),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(Icons.fitness_center, color: kNavy, size: size * 0.5),
    );
  }
}

/// การ์ดสีขาวมุมมน เงานุ่ม
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// InputDecoration กลาง (ป้ายชื่ออยู่ด้านบนช่อง จึงไม่ใช้ labelText)
InputDecoration authInputDecoration({
  IconData? icon,
  String? hint,
  Widget? suffix,
  Color fill = Colors.white,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: app.kNeutral),
    prefixIcon: icon == null ? null : Icon(icon, color: kIconMuted),
    suffixIcon: suffix,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    enabledBorder: border(const Color(0xFFCBD5E1)),
    focusedBorder: border(kGreen, 2),
    errorBorder: border(kError),
    focusedErrorBorder: border(kError, 2),
    errorStyle: const TextStyle(color: kError, height: 1.3),
  );
}

/// ช่องกรอกพร้อมป้ายชื่อด้านบน (ใส่ดอกจันแดงเมื่อ [required])
class AuthField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final Widget? suffix;
  final bool obscureText;
  final bool onCard; // true = อยู่บนการ์ดสีขาว ใช้พื้นช่องสีอ่อนให้แยกจากการ์ด
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final String? counter; // ข้อความมุมขวาของป้ายชื่อ เช่น '3 / 50'

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.required = false,
    this.hint,
    this.suffix,
    this.obscureText = false,
    this.onCard = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.counter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    color: kNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    if (required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: kError),
                      ),
                  ],
                ),
              ),
            ),
            if (counter != null)
              Text(
                counter!,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          style: const TextStyle(color: kNavy, fontSize: 16),
          cursorColor: kGreenDark,
          decoration: authInputDecoration(
            icon: icon,
            hint: hint,
            suffix: suffix,
            fill: onCard ? kFieldTint : Colors.white,
          ),
        ),
      ],
    );
  }
}

/// ปุ่มหลักสีเขียว มีเงาเรืองสี และสถานะกำลังโหลด
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.trailingIcon,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D00DC82),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kGreen,
          foregroundColor: kNavy,
          // ตอนกำลังโหลดปุ่มจะ disabled แต่ให้ยังเป็นสีเขียวอยู่
          disabledBackgroundColor: loading ? kGreen : const Color(0xFFBAE6D3),
          disabledForegroundColor: kNavy,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: kNavy,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

/// รูปโปรไฟล์วงกลม (โหลดจาก avatar_url ถ้าไม่มีหรือโหลดไม่ได้จะแสดงไอคอนแทน)
class UserAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final bool ring; // กรอบสีเขียวรอบรูป

  const UserAvatar({super.key, this.url, this.size = 40, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: kMint,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: kGreenDark, size: size * 0.55),
    );
    final u = (url ?? '').trim();

    final Widget image = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: u.isEmpty
            ? fallback
            : Image.network(
                u,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );

    if (!ring) return image;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kGreen, width: 3),
      ),
      child: image,
    );
  }
}

/// ป้ายเล็ก ๆ เช่น "ยืนยันแล้ว"
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.background = kMint,
    this.foreground = kGreenDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// หัวข้อส่วน: ไอคอน + ชื่อ + ข้อความรองด้านขวา
class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kGreenDark, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: kNavy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(color: kMuted, fontSize: 13)),
      ],
    );
  }
}

/// กล่องข้อความสีฟ้าอ่อนพร้อมไอคอน (ใช้เป็นหัวหน้าจอแก้ไขข้อมูล)
class AuthInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const AuthInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPanelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kMint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: kGreenDark, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 14,
                    height: 1.5,
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

/// แถบปุ่มล่างสุดของหน้าแก้ไข: ปุ่มบันทึกสีเขียว + ปุ่มยกเลิก
/// วางไว้ท้าย Column ของ body เพื่อให้เลื่อนขึ้นตามคีย์บอร์ด
class BottomActionBar extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  const BottomActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthPrimaryButton(
                    label: label,
                    leadingIcon: icon,
                    loading: loading,
                    onPressed: onPressed,
                  ),
                  TextButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

/// AppBar มาตรฐานของหน้าย่อย (พื้นสีเดียวกับหน้า ไม่มีเงา ชื่ออยู่ชิดซ้าย)
AppBar buildAppBar(String title) {
  return AppBar(
    title: Text(title),
    centerTitle: false,
    backgroundColor: kBg,
    foregroundColor: kNavy,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: const TextStyle(
      color: kNavy,
      fontSize: 18,
      fontWeight: FontWeight.w800,
    ),
  );
}