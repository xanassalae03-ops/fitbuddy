import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'register_page.dart';
import 'hello_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  void _handleLogin() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    // เช็กข้อมูลในตาราง login
    bool success = await DBHelper.login(username, password);

    if (!mounted) return;

    if (success) {
      // เข้าสู่ระบบสำเร็จ -> นำไปยังหน้า HelloPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HelloPage(username: username),
        ),
      );
    } else {
      _showMessage('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'ชื่อผู้ใช้ (Username)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสผ่าน (Password)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('สมัครสมาชิกที่นี่ครับ'),
            ),
          ],
        ),
      ),
    );
  }
}