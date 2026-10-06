import 'package:flutter/material.dart';
import 'constants.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? kError : kNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class AvatarCircle extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;

  const AvatarCircle({super.key, required this.url, required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first);

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: kMint,
      child: Text(initial, style: TextStyle(color: kGreenDark, fontWeight: FontWeight.bold, fontSize: radius * 0.9)),
    );

    if (url == null || url!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const Pill({super.key, required this.text, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: kIconMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: kMuted)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}