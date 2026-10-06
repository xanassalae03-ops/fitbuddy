import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bmi_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BMIProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "BMI Calculator",
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        fontFamily: 'Arial',
        // กำหนด style กลางไว้ที่เดียว ไม่ต้องเขียนซ้ำในแต่ละ widget
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      home: const BMIPage(),
    );
  }
}

// ================= หน้าแรก : กรอกข้อมูล =================

class BMIPage extends StatelessWidget {
  const BMIPage({super.key});

  // ช่วยสร้าง TextField แบบเดียวกัน ลดโค้ดซ้ำ
  Widget _buildField(TextEditingController c, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  // ช่วยสร้างปุ่มเลือกเพศแบบเดียวกัน ลดโค้ดซ้ำ
  // groupValue รับมาจาก provider.gender เพื่อไม่ต้อง watch ซ้ำในนี้
  Widget _genderTile(BuildContext context, String value, String groupValue) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(value),
        value: value,
        groupValue: groupValue,
        activeColor: Colors.pink,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => context.read<BMIProvider>().setGender(v!),
      ),
    );
  }

  // ให้ Provider คำนวณ แล้วค่อยตัดสินใจเรื่อง UI (SnackBar / navigate) ที่นี่
  void _handleCalculate(BuildContext context) {
    final success = context.read<BMIProvider>().calculateBMI();

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกส่วนสูงและน้ำหนักให้ถูกต้อง")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResultPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // watch ไว้เพื่อให้ radio ปุ่มเลือกเพศรีบิลด์เมื่อ gender เปลี่ยน
    final provider = context.watch<BMIProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("BMI Calculator"),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ข้อความตกแต่งด้านบน
              const Text(
                "BMI",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "คำนวณดัชนีมวลกาย",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // กล่องกรอกข้อมูล
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField(provider.nameController, "ชื่อ", Icons.person),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          const Icon(Icons.wc, color: Colors.grey),
                          const SizedBox(width: 5),
                          const Text("เพศ :", style: TextStyle(fontSize: 16)),
                          _genderTile(context, "ชาย", provider.gender),
                          _genderTile(context, "หญิง", provider.gender),
                        ],
                      ),
                      const SizedBox(height: 15),

                      _buildField(provider.heightController, "ส่วนสูง (cm)", Icons.height, isNumber: true),
                      const SizedBox(height: 15),
                      _buildField(provider.weightController, "น้ำหนัก (kg)", Icons.monitor_weight, isNumber: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: () => _handleCalculate(context),
                icon: const Icon(Icons.calculate),
                label: const Text("คำนวณ BMI"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= หน้าถัดไป : แสดงผลลัพธ์ =================

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ไม่ต้องรับ name/gender/bmi ผ่าน constructor อีกต่อไป ดึงจาก Provider ตรงๆ
    final provider = context.watch<BMIProvider>();
    final info = provider.info;
    final level = info["level"] as String;
    final color = info["color"] as Color;
    final advice = info["advice"] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ผลลัพธ์ BMI"),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // กล่องแสดงชื่อ เพศ และค่า BMI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      "${provider.resultName} (${provider.resultGender})",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "BMI ของคุณคือ ${provider.bmi.toStringAsFixed(1)}",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "($level)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // กล่องคำแนะนำ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lightbulb, color: Colors.amber),
                          SizedBox(width: 8),
                          Text("คำแนะนำ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(advice, style: const TextStyle(fontSize: 15, height: 1.5)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text("กลับไปคำนวณใหม่"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}