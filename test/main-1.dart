import 'package:flutter/material.dart';
import 'page1.dart'; // import หน้าแรกเข้ามาใช้งาน

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Page Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Page1(), // กำหนดให้ Page1 เป็นหน้าเริ่มต้น
    );
  }
}