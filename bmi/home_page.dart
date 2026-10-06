import 'package:flutter/material.dart';
import 'bmi_colors.dart';
import 'bmi_gauge.dart';
import 'bmi_record.dart';
import 'db_helper.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomePage({super.key, required this.isDarkMode, required this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  List<BmiRecord> _records = [];
  bool _loadingHistory = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _loadError = null;
    });
    try {
      final data = await DBHelper.getRecords();
      setState(() {
        _records = data;
        _loadingHistory = false;
      });
    } catch (_) {
      setState(() {
        _loadError = 'โหลดประวัติไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';
        _loadingHistory = false;
      });
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? BmiColors.obese : BmiColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getRecommendation(String category) {
    switch (category) {
      case 'น้ำหนักน้อย':
        return 'ควรรับประทานอาหารที่มีสารอาหารครบถ้วน เพิ่มโปรตีนและแคลอรี และออกกำลังกายเพื่อสร้างมวลกล้ามเนื้อ';
      case 'ปกติ':
        return 'สุขภาพดีเยี่ยม! ควบคุมการรับประทานอาหารให้สมดุลและออกกำลังกายอย่างสม่ำเสมอเพื่อรักษาระดับน้ำหนักนี้ไว้';
      case 'น้ำหนักเกิน':
        return 'ควรเริ่มควบคุมปริมาณน้ำตาลและไขมัน เพิ่มการออกกำลังกายอย่างน้อย 150 นาทีต่อสัปดาห์';
      case 'อ้วน':
        return 'ควรปรับพฤติกรรมการทานอาหาร ลดของหวาน ของมัน ของทอด และเพิ่มการออกกำลังกายแบบแอโรบิก';
      case 'อ้วนมาก':
        return 'ควรขอคำปรึกษาจากแพทย์หรือนักโภชนาการเพื่อวางแผนลดน้ำหนักอย่างปลอดภัยและถูกวิธี';
      default:
        return 'ดูแลสุขภาพและออกกำลังกายอย่างสม่ำเสมอ';
    }
  }

  void _showUserDetailModal(BmiRecord record) {
    final color = BmiColors.forCategory(record.category);
    final recommendation = _getRecommendation(record.category);

    final cardBg = widget.isDarkMode ? BmiColors.cardDark : BmiColors.cardLight;
    final inkColor = widget.isDarkMode ? BmiColors.inkDark : BmiColors.inkLight;
    final faintColor = widget.isDarkMode ? BmiColors.inkFaintDark : BmiColors.inkFaintLight;
    final innerBg = widget.isDarkMode ? BmiColors.bgDark : BmiColors.bgLight;
    final borderColor = widget.isDarkMode ? BmiColors.borderDark : BmiColors.borderLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                record.name.isNotEmpty ? record.name : 'ไม่ระบุชื่อ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: inkColor),
              ),
              const SizedBox(height: 4),
              Text(
                'ส่วนสูง ${record.heightCm} ซม. | น้ำหนัก ${record.weightKg} กก.',
                style: TextStyle(color: faintColor),
              ),
              const SizedBox(height: 20),
              AnimatedBmiGauge(targetBmi: record.bmi, isDarkMode: widget.isDarkMode),
              const SizedBox(height: 12),
              Text(
                record.bmi.toStringAsFixed(1),
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: inkColor),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(record.category, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: innerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ข้อแนะนำสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold, color: inkColor)),
                          const SizedBox(height: 4),
                          Text(recommendation, style: TextStyle(fontSize: 13, color: inkColor, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _calculateAndSave() async {
    final name = _nameController.text.trim();
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (name.isEmpty) {
      _showSnack('กรุณากรอกชื่อก่อนบันทึก', isError: true);
      return;
    }
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      _showSnack('กรอกส่วนสูงและน้ำหนักเป็นตัวเลขให้ถูกต้อง', isError: true);
      return;
    }

    setState(() => _submitting = true);
    Map<String, dynamic>? result;
    try {
      result = await DBHelper.createRecord(name: name, heightCm: height, weightKg: weight);
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result != null) {
      _nameController.clear();
      _heightController.clear();
      _weightController.clear();
      FocusScope.of(context).unfocus();
      await _loadHistory();
      _showSnack('บันทึกผลเรียบร้อยแล้ว');
    } else {
      _showSnack('บันทึกไม่สำเร็จ ลองอีกครั้ง', isError: true);
    }
  }

  Future<void> _confirmDelete(BmiRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('ลบรายการนี้?'),
        content: Text('ลบผล BMI ${record.bmi} เมื่อวันที่ ${_formatDate(record.createdAt)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: TextStyle(color: widget.isDarkMode ? BmiColors.inkFaintDark : BmiColors.inkFaintLight)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BmiColors.obese),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bool ok;
      try {
        ok = await DBHelper.deleteRecord(record.id);
      } catch (_) {
        ok = false;
      }
      if (!mounted) return;
      if (ok) {
        await _loadHistory();
        _showSnack('ลบรายการแล้ว');
      } else {
        _showSnack('ลบไม่สำเร็จ', isError: true);
      }
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inkColor = widget.isDarkMode ? BmiColors.inkDark : BmiColors.inkLight;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.monitor_heart_outlined, color: BmiColors.teal),
            SizedBox(width: 8),
            Text('คำนวณค่า BMI'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: BmiColors.teal,
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputCard(),
              const SizedBox(height: 20),
              Text('ประวัติการวัด (กดที่รายการเพื่อดูรายละเอียด)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: inkColor)),
              const SizedBox(height: 8),
              _buildHistory(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    final cardBg = widget.isDarkMode ? BmiColors.cardDark : BmiColors.cardLight;
    final borderColor = widget.isDarkMode ? BmiColors.borderDark : BmiColors.borderLight;
    final faintColor = widget.isDarkMode ? BmiColors.inkFaintDark : BmiColors.inkFaintLight;
    final inkColor = widget.isDarkMode ? BmiColors.inkDark : BmiColors.inkLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('กรอกข้อมูลของคุณ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: faintColor, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            style: TextStyle(color: inkColor),
            decoration: const InputDecoration(hintText: 'ชื่อ *'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  style: TextStyle(color: inkColor),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'ส่วนสูง', suffixText: 'ซม.'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  style: TextStyle(color: inkColor),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'น้ำหนัก', suffixText: 'กก.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: BmiColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submitting ? null : _calculateAndSave,
              icon: _submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.calculate_outlined),
              label: Text(_submitting ? 'กำลังบันทึก...' : 'คำนวณและบันทึกผล'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final cardBg = widget.isDarkMode ? BmiColors.cardDark : BmiColors.cardLight;
    final borderColor = widget.isDarkMode ? BmiColors.borderDark : BmiColors.borderLight;
    final inkColor = widget.isDarkMode ? BmiColors.inkDark : BmiColors.inkLight;
    final faintColor = widget.isDarkMode ? BmiColors.inkFaintDark : BmiColors.inkFaintLight;

    if (_loadingHistory) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(color: BmiColors.teal)));
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(_loadError!, textAlign: TextAlign.center, style: TextStyle(color: faintColor)),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _loadHistory, icon: const Icon(Icons.refresh), label: const Text('ลองอีกครั้ง')),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_toggle_off, size: 40, color: faintColor),
              const SizedBox(height: 8),
              Text('ยังไม่มีประวัติ ลองคำนวณและบันทึกผลแรกของคุณ', style: TextStyle(color: faintColor)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final r = _records[index];
        final color = BmiColors.forCategory(r.category);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showUserDetailModal(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(width: 4, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name.isNotEmpty ? r.name : 'ไม่ระบุชื่อ', style: TextStyle(fontWeight: FontWeight.w600, color: inkColor)),
                          Text('${r.heightCm} ซม. · ${r.weightKg} กก. · ${_formatDate(r.createdAt)}', style: TextStyle(fontSize: 12, color: faintColor)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(r.bmi.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w700, color: inkColor)),
                        Text(r.category, style: TextStyle(fontSize: 11, color: color)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: BmiColors.obese),
                      onPressed: () => _confirmDelete(r),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}