import 'package:flutter/material.dart';

import 'api_service.dart';
import 'constants.dart';
import 'location_picker_page.dart';
import 'map_preview.dart';
import 'models.dart';
import 'widgets.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  static const _costTypes = {
    'FREE': 'ฟรี ไม่มีค่าใช้จ่าย',
    'SPLIT_EQUALLY': 'หารค่าใช้จ่ายเท่ากัน',
    'FIXED_PRICE': 'ราคาคงที่ต่อคน',
  };

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _max = TextEditingController(text: '8');
  final _cost = TextEditingController();

  List<SportCategory> _categories = [];
  bool _loadingCats = true;
  String? _catsError;

  int? _sportId;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  String _costType = 'FREE';
  bool _saving = false;

  // หมุดที่ปักบนแผนที่
  double? _lat;
  double? _lng;
  String? _lastAutoName; // ชื่อสถานที่ที่เติมให้อัตโนมัติจากหมุด

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _max.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCats = true;
      _catsError = null;
    });
    try {
      final cats = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loadingCats = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _catsError = e.message;
        _loadingCats = false;
      });
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _fmtTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickLocation() async {
    final r = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLat: _lat,
          initialLng: _lng,
        ),
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      _lat = r.lat;
      _lng = r.lng;
      // เติมชื่อสถานที่ให้ ถ้ายังว่าง หรือยังเป็นชื่อที่ระบบเติมให้ก่อนหน้า (ไม่ทับที่ผู้ใช้พิมพ์เอง)
      if (r.name != null &&
          (_location.text.trim().isEmpty || _location.text == _lastAutoName)) {
        _location.text = r.name!;
      }
      _lastAutoName = r.name;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _start : _end) ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      showSnack(context, 'กรุณาปักหมุดสถานที่บนแผนที่', error: true);
      return;
    }
    if (_date == null) {
      showSnack(context, 'กรุณาเลือกวันที่', error: true);
      return;
    }
    if (_start == null || _end == null) {
      showSnack(context, 'กรุณาเลือกเวลาเริ่มและเวลาสิ้นสุด', error: true);
      return;
    }
    if (_minutes(_end!) <= _minutes(_start!)) {
      showSnack(context, 'เวลาสิ้นสุดต้องหลังเวลาเริ่ม', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.createEvent(
        hostId: Session.userId,
        sportId: _sportId!,
        title: _title.text,
        description: _description.text,
        locationName: _location.text,
        latitude: _lat!,
        longitude: _lng!,
        eventDate: _fmtDate(_date!),
        startTime: _fmtTime(_start!),
        endTime: _fmtTime(_end!),
        maxParticipants: int.parse(_max.text.trim()),
        costType: _costType,
        costAmount:
            _costType == 'FREE' ? 0 : double.parse(_cost.text.trim()),
      );
      if (!mounted) return;
      showSnack(context, 'สร้างกิจกรรมสำเร็จ');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('สร้างนัดกิจกรรม'),
        backgroundColor: kSurface,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loadingCats
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _catsError != null
              ? Center(
                  child:
                      ErrorView(message: _catsError!, onRetry: _loadCategories))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _title,
                            maxLength: 255,
                            decoration: _dec('ชื่อกิจกรรม',
                                hint: 'เช่น วิ่งเย็นสวนสาธารณะ 5 กม.'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกชื่อกิจกรรม'
                                : null,
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: _sportId,
                            decoration: _dec('ชนิดกีฬา'),
                            items: [
                              for (final c in _categories)
                                DropdownMenuItem(
                                    value: c.id, child: Text(c.nameTh)),
                            ],
                            onChanged: (v) => setState(() => _sportId = v),
                            validator: (v) =>
                                v == null ? 'กรุณาเลือกชนิดกีฬา' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _description,
                            maxLines: 3,
                            decoration: _dec('รายละเอียด (ไม่บังคับ)'),
                          ),
                          const SizedBox(height: 14),
                          _buildMapSection(),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _location,
                            maxLength: 150,
                            decoration: _dec('ชื่อสถานที่',
                                hint: 'เช่น สวนสาธารณะ ประตู 2'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกชื่อสถานที่'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _pickerTile(
                            icon: Icons.calendar_today_outlined,
                            label: _date == null
                                ? 'เลือกวันที่'
                                : thaiDate(_fmtDate(_date!)),
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _pickerTile(
                                  icon: Icons.schedule,
                                  label: _start == null
                                      ? 'เวลาเริ่ม'
                                      : _fmtTime(_start!),
                                  onTap: () => _pickTime(isStart: true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _pickerTile(
                                  icon: Icons.schedule,
                                  label: _end == null
                                      ? 'เวลาสิ้นสุด'
                                      : _fmtTime(_end!),
                                  onTap: () => _pickTime(isStart: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _max,
                            keyboardType: TextInputType.number,
                            decoration:
                                _dec('จำนวนผู้เข้าร่วมสูงสุด (รวมผู้จัด)'),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null || n < 2 || n > 100) {
                                return 'ต้องอยู่ระหว่าง 2 - 100 คน';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _costType,
                            decoration: _dec('ค่าใช้จ่าย'),
                            items: [
                              for (final e in _costTypes.entries)
                                DropdownMenuItem(
                                    value: e.key, child: Text(e.value)),
                            ],
                            onChanged: (v) =>
                                setState(() => _costType = v ?? 'FREE'),
                          ),
                          if (_costType != 'FREE') ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _cost,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _dec(_costType == 'FIXED_PRICE'
                                  ? 'ราคาต่อคน (บาท)'
                                  : 'ค่าใช้จ่ายรวมโดยประมาณ (บาท)'),
                              validator: (v) {
                                final n = double.tryParse((v ?? '').trim());
                                if (n == null || n < 0 || n > 100000) {
                                  return 'กรุณากรอกจำนวนเงินให้ถูกต้อง';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: FilledButton(
                              onPressed: _saving ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: kGreen,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    )
                                  : const Text('สร้างกิจกรรม',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildMapSection() {
    if (_lat == null || _lng == null) {
      return InkWell(
        onTap: _pickLocation,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBlue.withAlpha(90)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_location_alt_outlined, color: kBlue, size: 36),
              SizedBox(height: 6),
              Text('ปักหมุดสถานที่บนแผนที่',
                  style: TextStyle(
                      color: kBlue, fontWeight: FontWeight.bold, fontSize: 15)),
              Text('ค้นหาชื่อสถานที่ หรือเลื่อนแผนที่เอง',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MapPreview(lat: _lat!, lng: _lng!, height: 160, onTap: _pickLocation),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            TextButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('เปลี่ยนตำแหน่ง'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: kGreen),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}