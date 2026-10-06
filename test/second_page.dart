import 'package:flutter/material.dart';

class SecondPage extends StatelessWidget {
  // รับค่าเข้ามาเป็น Map
  final Map<String, dynamic> data;

  const SecondPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // ดึงค่าออกจาก Map
    final String name = data['name'] ?? '';
    final String gender = data['gender'] ?? 'ชาย';
    final double weight = data['weight'] ?? 0.0;
    final double height = data['height'] ?? 0.0;

    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);

    final String label;
    final Color color;
    final IconData mood;
    final String description;

    if (bmi < 18.5) {
      label = 'น้ำหนักน้อยกว่าเกณฑ์';
      color = const Color(0xFF0284C7);
      mood = Icons.sentiment_dissatisfied_rounded;
      description = 'ควรรับประทานอาหารให้ครบ 5 หมู่ และเพิ่มปริมาณแคลอรี';
    } else if (bmi < 25) {
      label = 'น้ำหนักปกติ (สุขภาพดี)';
      color = const Color(0xFF16A34A);
      mood = Icons.sentiment_very_satisfied_rounded;
      description = 'สุขภาพดีเยี่ยม! ควบคุมอาหารและออกกำลังกายสม่ำเสมอต่อไป';
    } else if (bmi < 30) {
      label = 'น้ำหนักเกิน (ท่วม)';
      color = const Color(0xFFD97706);
      mood = Icons.sentiment_neutral_rounded;
      description = 'ควรเริ่มควบคุมอาหาร และออกกำลังกายอย่างน้อย 150 นาที/สัปดาห์';
    } else {
      label = 'อยู่ในเกณฑ์อ้วน';
      color = const Color(0xFFDC2626);
      mood = Icons.sentiment_very_dissatisfied_rounded;
      description = 'มีความเสี่ยงต่อโรคเรื้อรัง ควรปรึกษาผู้เชี่ยวชาญหรือปรับพฤติกรรม';
    }

    final isMale = gender == 'ชาย';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'ผลการวิเคราะห์ BMI',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF00796B).withValues(alpha: 0.3),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                      child: Icon(
                        isMale ? Icons.male_rounded : Icons.female_rounded,
                        size: 36,
                        color: isMale ? Colors.blue : Colors.pink,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ส่วนสูง $height ซม. • น้ำหนัก $weight กก.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(mood, size: 80, color: color),
                    const SizedBox(height: 16),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ดัชนีมวลกาย (BMI)',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text('กลับไปที่หน้าแรก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00796B),
                    side: const BorderSide(color: Color(0xFF00796B), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}