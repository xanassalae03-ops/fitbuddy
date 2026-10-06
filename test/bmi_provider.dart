import 'package:flutter/material.dart';

// จัดการ state ทั้งหมดของ BMI Calculator แทนการใช้ setState
// ครอบคลุมทั้งข้อมูลฟอร์ม (name, gender, height, weight)
// และผลลัพธ์การคำนวณ (bmi, level, color, advice)
class BMIProvider extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  String _gender = "ชาย";
  String get gender => _gender;

  double _bmi = 0;
  double get bmi => _bmi;

  String _resultName = "";
  String get resultName => _resultName;

  String _resultGender = "ชาย";
  String get resultGender => _resultGender;

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  // คำนวณ BMI จากค่าที่กรอกใน controller
  // คืนค่า true ถ้าคำนวณสำเร็จ, false ถ้าข้อมูลไม่ถูกต้อง
  // (ไม่ยุ่งกับ BuildContext/SnackBar ตรงนี้ ปล่อยให้ widget เป็นคนจัดการ UI)
  bool calculateBMI() {
    final double height = double.tryParse(heightController.text) ?? 0;
    final double weight = double.tryParse(weightController.text) ?? 0;

    if (height <= 0 || weight <= 0) {
      return false;
    }

    _bmi = weight / ((height / 100) * (height / 100));
    _resultName = nameController.text.isEmpty ? "คุณ" : nameController.text;
    _resultGender = _gender;

    notifyListeners();
    return true;
  }

  // คำนวณระดับ/สี/คำแนะนำ ครั้งเดียวจบ แทนการเช็คเงื่อนไขซ้ำ 3 รอบ
  Map<String, dynamic> get info {
    if (_bmi < 18.5) {
      return {
        "level": "น้ำหนักน้อย",
        "color": Colors.blue,
        "advice":
            "ร่างกายของคุณมีน้ำหนักน้อยกว่าเกณฑ์มาตรฐาน ควรรับประทานอาหารให้ครบ 5 หมู่ "
            "เน้นอาหารที่มีโปรตีนสูง เช่น ไข่ เนื้อสัตว์ ถั่วต่างๆ และนมไขมันเต็มส่วน "
            "เพิ่มมื้ออาหารหรือของว่างที่มีประโยชน์ระหว่างวัน และควรออกกำลังกายแบบเสริมสร้างกล้ามเนื้อ "
            "เช่น ยกน้ำหนักเบาๆ ควบคู่ไปด้วย เพื่อเพิ่มมวลกล้ามเนื้อแทนไขมัน",
      };
    } else if (_bmi < 23) {
      return {
        "level": "น้ำหนักปกติ",
        "color": Colors.green,
        "advice":
            "ยินดีด้วย! น้ำหนักของคุณอยู่ในเกณฑ์ปกติและเหมาะสมกับส่วนสูงแล้ว "
            "ควรรักษาพฤติกรรมการกินที่สมดุลต่อไป กินผักผลไม้ให้เพียงพอ "
            "ออกกำลังกายอย่างสม่ำเสมออย่างน้อยสัปดาห์ละ 150 นาที เช่น เดินเร็ว วิ่ง หรือว่ายน้ำ "
            "พักผ่อนให้เพียงพอวันละ 7-8 ชั่วโมง และหมั่นตรวจสุขภาพประจำปีเพื่อติดตามสุขภาพอย่างต่อเนื่อง",
      };
    } else if (_bmi < 25) {
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
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }
}
