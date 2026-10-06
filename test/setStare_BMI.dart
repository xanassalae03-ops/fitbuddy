import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "BMI Calculator",
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF2F6F9),
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
            backgroundColor: Colors.teal,
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

class BMIPage extends StatefulWidget {
  const BMIPage({super.key});

  @override
  State<BMIPage> createState() => _BMIPageState();
}

class _BMIPageState extends State<BMIPage> {
  final nameController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  String gender = "ชาย";

  void calculateBMI() {
    double height = double.tryParse(heightController.text) ?? 0;
    double weight = double.tryParse(weightController.text) ?? 0;

    if (height <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกส่วนสูงและน้ำหนักให้ถูกต้อง")),
      );
      return;
    }

    double bmi = weight / ((height / 100) * (height / 100));
    String displayName = nameController.text.isEmpty ? "คุณ" : nameController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(name: displayName, gender: gender, bmi: bmi),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  // ช่วยสร้าง TextField แบบเดียวกัน ลดโค้ดซ้ำ
  Widget _buildField(TextEditingController c, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  // ช่วยสร้างปุ่มเลือกเพศแบบเดียวกัน ลดโค้ดซ้ำ
  Widget _genderTile(String value) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(value),
        value: value,
        groupValue: gender,
        activeColor: Colors.teal,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => gender = v!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BMI Calculator"),
        centerTitle: true,
        backgroundColor: Colors.teal,
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
                  color: Colors.teal,
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
                      _buildField(nameController, "ชื่อ", Icons.person),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          const Icon(Icons.wc, color: Colors.grey),
                          const SizedBox(width: 5),
                          const Text("เพศ :", style: TextStyle(fontSize: 16)),
                          _genderTile("ชาย"),
                          _genderTile("หญิง"),
                        ],
                      ),
                      const SizedBox(height: 15),

                      _buildField(heightController, "ส่วนสูง (cm)", Icons.height, isNumber: true),
                      const SizedBox(height: 15),
                      _buildField(weightController, "น้ำหนัก (kg)", Icons.monitor_weight, isNumber: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: calculateBMI,
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
  final String name;
  final String gender;
  final double bmi;

  const ResultPage({super.key, required this.name, required this.gender, required this.bmi});

  // คำนวณระดับ/สี/คำแนะนำ ครั้งเดียวจบ แทนการเช็คเงื่อนไขซ้ำ 3 รอบ
  Map<String, dynamic> get _info {
    if (bmi < 18.5) {
      return {
        "level": "น้ำหนักน้อย",
        "color": Colors.blue,
        "advice":
            "ร่างกายของคุณมีน้ำหนักน้อยกว่าเกณฑ์มาตรฐาน ควรรับประทานอาหารให้ครบ 5 หมู่ "
            "เน้นอาหารที่มีโปรตีนสูง เช่น ไข่ เนื้อสัตว์ ถั่วต่างๆ และนมไขมันเต็มส่วน "
            "เพิ่มมื้ออาหารหรือของว่างที่มีประโยชน์ระหว่างวัน และควรออกกำลังกายแบบเสริมสร้างกล้ามเนื้อ "
            "เช่น ยกน้ำหนักเบาๆ ควบคู่ไปด้วย เพื่อเพิ่มมวลกล้ามเนื้อแทนไขมัน",
      };
    } else if (bmi < 23) {
      return {
        "level": "น้ำหนักปกติ",
        "color": Colors.green,
        "advice":
            "ยินดีด้วย! น้ำหนักของคุณอยู่ในเกณฑ์ปกติและเหมาะสมกับส่วนสูงแล้ว "
            "ควรรักษาพฤติกรรมการกินที่สมดุลต่อไป กินผักผลไม้ให้เพียงพอ "
            "ออกกำลังกายอย่างสม่ำเสมออย่างน้อยสัปดาห์ละ 150 นาที เช่น เดินเร็ว วิ่ง หรือว่ายน้ำ "
            "พักผ่อนให้เพียงพอวันละ 7-8 ชั่วโมง และหมั่นตรวจสุขภาพประจำปีเพื่อติดตามสุขภาพอย่างต่อเนื่อง",
      };
    } else if (bmi < 25) {
      return {
        "level": "น้ำหนักเกิน",
        "color": Colors.orange,
        "advice":
            "น้ำหนักของคุณเริ่มเกินเกณฑ์มาตรฐานเล็กน้อย ควรเริ่มควบคุมปริมาณอาหารในแต่ละมื้อ "
            "ลดอาหารที่มีน้ำตาล ไขมัน และโซเดียมสูง เช่น ของทอด ขนมหวาน และเครื่องดื่มรสหวาน "
            "เพิ่มการออกกำลังกายให้มากขึ้น เช่น เดินหรือปั่นจักรยานอย่างน้อยวันละ 30 นาที "
            "และควรชั่งน้ำหนักติดตามผลอย่างสม่ำเสมอเพื่อไม่ให้น้ำหนักเพิ่มขึ้นต่อเนื่อง",
      };
    } else {
      return {
        "level": "โรคอ้วน",
        "color": Colors.red,
        "advice":
            "น้ำหนักของคุณอยู่ในเกณฑ์โรคอ้วน ซึ่งอาจเพิ่มความเสี่ยงต่อโรคเรื้อรังต่างๆ "
            "เช่น เบาหวาน ความดันโลหิตสูง ไขมันในเลือดสูง และโรคหัวใจและหลอดเลือด "
            "ควรปรึกษาแพทย์หรือนักโภชนาการเพื่อวางแผนลดน้ำหนักอย่างถูกวิธีและปลอดภัย "
            "ปรับพฤติกรรมการกินอย่างจริงจัง ลดอาหารพลังงานสูง เพิ่มการออกกำลังกายอย่างค่อยเป็นค่อยไป "
            "และติดตามสุขภาพอย่างใกล้ชิดเพื่อป้องกันภาวะแทรกซ้อนในระยะยาว",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _info["level"] as String;
    final color = _info["color"] as Color;
    final advice = _info["advice"] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ผลลัพธ์ BMI"),
        centerTitle: true,
        backgroundColor: Colors.teal,
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
                      "$name ($gender)",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "BMI ของคุณคือ ${bmi.toStringAsFixed(1)}",
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