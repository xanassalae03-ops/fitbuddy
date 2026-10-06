import 'package:flutter/material.dart';
import 'db_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  void _handleRegister() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    // เช็กว่า Username ซ้ำในตาราง login ไหม
    bool exists = await DBHelper.checkUserExists(username);
    if (exists) {
      _showMessage('ชื่อผู้ใช้นี้ถูกใช้งานแล้ว');
      return;
    }

    // บันทึกลงตาราง login
    await DBHelper.register(username, password);

    if (!mounted) return;
    _showMessage('สมัครสมาชิกสำเร็จ!');
    Navigator.pop(context); // กลับหน้า Login
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'ตั้งชื่อผู้ใช้ (Username)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'ตั้งรหัสผ่าน (Password)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleRegister,
                child: const Text('ยืนยันสมัครสมาชิก', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}