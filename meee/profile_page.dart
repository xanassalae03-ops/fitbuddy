import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'login_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>>? onUserUpdated;

  const ProfilePage({super.key, required this.user, this.onUserUpdated});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, dynamic> _user;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
  }

  String _text(String key) => (_user[key] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthCard(
                child: Column(
                  children: [
                    UserAvatar(url: _text('avatar_url'), size: 80, ring: true),
                    const SizedBox(height: 16),
                    Text(_text('full_name'), style: const TextStyle(color: kNavy, fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_text('nickname').isNotEmpty)
                      Text('(${_text('nickname')})', style: const TextStyle(color: kMuted)),
                    const SizedBox(height: 8),
                    Text(_text('email'), style: const TextStyle(color: kMuted)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.settings, color: kNavy),
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsPage(user: _user, onUserChanged: (u) => setState(() => _user = u)),
                          ),
                        );
                        if (updated != null && widget.onUserUpdated != null) {
                          widget.onUserUpdated!(updated);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
                child: const Text('ออกจากระบบ', style: TextStyle(color: kError)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}