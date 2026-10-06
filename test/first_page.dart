import 'package:flutter/material.dart';
import 'second_page.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _gender = 'ชาย';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);

    if (_nameCtrl.text.trim().isEmpty ||
        weight == null || weight <= 0 ||
        height == null || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('กรุณากรอกข้อมูลให้ถูกต้องครบถ้วน'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // สร้าง Map รวบรวมข้อมูลทั้งหมด
    final Map<String, dynamic> bmiData = {
      'name': _nameCtrl.text.trim(),
      'gender': _gender,
      'weight': weight,
      'height': height,
    };

    // ส่ง Map ไปยังหน้าสอง
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(data: bmiData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'คำนวณดัชนีมวลกาย',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00796B),
        elevation: 2,
        shadowColor: const Color(0xFF00796B).withValues(alpha: 0.3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'BMI Calculator',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อ - นามสกุล',
                prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF00796B)),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    title: 'ชาย',
                    icon: Icons.male_rounded,
                    color: Colors.blue,
                    isSelected: _gender == 'ชาย',
                    onTap: () => setState(() => _gender = 'ชาย'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _GenderCard(
                    title: 'หญิง',
                    icon: Icons.female_rounded,
                    color: Colors.pink,
                    isSelected: _gender == 'หญิง',
                    onTap: () => setState(() => _gender = 'หญิง'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'น้ำหนัก (กก.)',
                      prefixIcon: Icon(Icons.fitness_center_rounded, color: Color(0xFF00796B)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'ส่วนสูง (ซม.)',
                      prefixIcon: Icon(Icons.height_rounded, color: Color(0xFF00796B)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined, size: 22),
                label: const Text(
                  'คำนวณผล',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: const Color(0xFF00796B).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 26),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}