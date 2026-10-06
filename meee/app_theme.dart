import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

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
            ? const [BoxShadow(color: Color(0x6600D67E), blurRadius: 32, offset: Offset(0, 8))]
            : null,
      ),
      child: Icon(Icons.fitness_center, color: kNavy, size: size * 0.5),
    );
  }
}

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
          BoxShadow(color: Color(0x140F1E3C), blurRadius: 32, offset: Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}

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
    hintStyle: const TextStyle(color: Color(0xFF8A97AE)),
    prefixIcon: icon == null ? null : Icon(icon, color: kIconMuted),
    suffixIcon: suffix,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    enabledBorder: border(const Color(0xFFE4E8F4)),
    focusedBorder: border(kGreen, 2),
    errorBorder: border(kError),
    focusedErrorBorder: border(kError, 2),
  );
}

class AuthField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final Widget? suffix;
  final bool obscureText;
  final bool onCard;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

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
    this.inputFormatters,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(color: kNavy, fontSize: 15, fontWeight: FontWeight.w700),
            children: [
              if (required) const TextSpan(text: ' *', style: TextStyle(color: kError)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: kNavy, fontSize: 16),
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

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: kGreen,
        foregroundColor: kNavy,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: kNavy))
          : Text(label),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final bool ring;

  const UserAvatar({super.key, this.url, this.size = 40, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: kMint,
      alignment: Alignment.center,
      child: Icon(Icons.person, color: kGreenDark, size: size * 0.55),
    );
    final u = (url ?? '').trim();

    final image = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: u.isEmpty
            ? fallback
            : Image.network(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
      ),
    );

    if (!ring) return image;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kGreen, width: 3)),
      child: image,
    );
  }
}

class BottomActionBar extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const BottomActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x140F1E3C), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: AuthPrimaryButton(label: label, loading: loading, onPressed: onPressed),
      ),
    );
  }
}

AppBar buildAppBar(String title) {
  return AppBar(
    title: Text(title),
    backgroundColor: kBg,
    foregroundColor: kNavy,
    elevation: 0,
    titleTextStyle: const TextStyle(color: kNavy, fontSize: 18, fontWeight: FontWeight.w800),
  );
}