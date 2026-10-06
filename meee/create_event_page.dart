import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'location_picker_page.dart';
import 'models.dart';

class CreateEventPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const CreateEventPage({super.key, required this.user});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _max = TextEditingController(text: '8');

  List<SportCategory> _categories = [];
  int? _sportId;
  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ApiService.getCategories().then((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _lat == null) return;
    setState(() => _saving = true);
    try {
      await ApiService.createEvent(
        hostId: userIdOf(widget.user),
        sportId: _sportId!,
        title: _title.text,
        description: _description.text,
        locationName: _location.text,
        latitude: _lat!,
        longitude: _lng!,
        eventDate: '2026-10-01',
        startTime: '18:00',
        endTime: '20:00',
        maxParticipants: int.parse(_max.text),
        costType: 'FREE',
        costAmount: 0,
      );
      if (!mounted) return;
      showAppToast(context, 'สร้างกิจกรรมสำเร็จ');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('สร้างนัดกิจกรรม'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AuthField(label: 'ชื่อกิจกรรม', controller: _title, icon: Icons.event, required: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _sportId,
                decoration: authInputDecoration(icon: Icons.sports, hint: 'เลือกชนิดกีฬา'),
                items: [for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.nameTh))],
                onChanged: (v) => setState(() => _sportId = v),
              ),
              const SizedBox(height: 16),
              AuthField(label: 'ชื่อสถานที่', controller: _location, icon: Icons.place, required: true),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final loc = await Navigator.push<PickedLocation>(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPickerPage()),
                  );
                  if (loc != null) {
                    setState(() {
                      _lat = loc.lat;
                      _lng = loc.lng;
                      if (loc.name != null) _location.text = loc.name!;
                    });
                  }
                },
                icon: const Icon(Icons.map, color: kGreenDark),
                label: Text(_lat == null ? 'ปักหมุดบนแผนที่' : 'เปลี่ยนหมุดสถานที่'),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(label: 'สร้างกิจกรรม', loading: _saving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}