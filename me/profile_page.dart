import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'constants.dart';
import 'models.dart';
import 'settings_page.dart' show SettingsPage;
import 'widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _hasVerifiedProfile(AppUser user) =>
      (user.bio?.trim().isNotEmpty ?? false) &&
      (user.avatarUrl?.trim().isNotEmpty ?? false);

  Map<String, dynamic> _profileData(AppUser user) => {
    'id': user.id,
    'email': user.email,
    'full_name': user.fullName,
    'nickname': user.nickname,
    'phone_number': user.phone,
    'bio': user.bio,
    'avatar_url': user.avatarUrl,
    'role': user.role,
    'trust_score': user.trustScore,
    'total_completed_events': user.totalCompletedEvents,
    'is_verified': _hasVerifiedProfile(user),
  };

  Future<void> _openSettings(BuildContext context, AppUser user) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          user: _profileData(user),
          onUserChanged: (updated) {
            Session.user = AppUser.fromJson(updated);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Session.user = null;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.user;
    final isVerified = u != null && _hasVerifiedProfile(u);

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: u == null
            ? const Center(child: Text('ไม่พบข้อมูลผู้ใช้'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: 'ตั้งค่าบัญชี',
                      onPressed: () => _openSettings(context, u),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                  Center(
                    child: AvatarCircle(
                      url: u.avatarUrl,
                      name: u.displayName,
                      radius: 44,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    u.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  if (u.nickname != null)
                    Text(
                      '(${u.nickname})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (u.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      u.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          Icons.verified_user_outlined,
                          u.trustScore.toStringAsFixed(1),
                          'คะแนนความน่าเชื่อถือ',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _stat(
                          Icons.emoji_events_outlined,
                          '${u.totalCompletedEvents}',
                          'กิจกรรมที่เข้าร่วมแล้ว',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(u.email),
                        ),
                        if (u.phone != null)
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: Text(u.phone!),
                          ),
                        ListTile(
                          leading: Icon(
                            isVerified
                                ? Icons.verified
                                : Icons.verified_outlined,
                            color: isVerified ? kGreen : Colors.grey,
                          ),
                          title: Text(
                            isVerified
                                ? 'ยืนยันตัวตนแล้ว'
                                : 'ยังไม่ได้ยืนยันตัวตน',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (u.role == 'ADMIN') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardPage(),
                          ),
                        ),
                        icon: const Icon(Icons.dashboard_outlined),
                        label: const Text('แดชบอร์ดผู้ดูแล'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kInk,
                          foregroundColor: kBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: kDanger),
                      label: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(color: kDanger),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kDanger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, color: kGreen),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    ),
  );
}
