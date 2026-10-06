import 'package:flutter/material.dart';

import 'api_service.dart';
import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

enum _Period { today, week, month, year, custom }

/// ข้อมูลกราฟ 1 ชุด (แปลงจาก series ที่ API ส่งมา)
class _Series {
  final String bucket; // hour / day / month
  final List<int> values;
  final List<String> labels;
  final int highlight;

  const _Series(this.bucket, this.values, this.labels, this.highlight);
}

/// แดชบอร์ดผู้ดูแลระบบ (เข้าได้เฉพาะผู้ใช้ role = ADMIN)
/// เลือกช่วงเวลาได้: วันนี้ / สัปดาห์นี้ / เดือนนี้ / ปีนี้ / กำหนดเอง
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const _periodLabels = {
    _Period.today: 'วันนี้',
    _Period.week: 'สัปดาห์นี้',
    _Period.month: 'เดือนนี้',
    _Period.year: 'ปีนี้',
    _Period.custom: 'กำหนดเอง',
  };
  static const _statusLabels = {
    'UPCOMING': 'เปิดรับสมัคร',
    'ONGOING': 'กำลังจัด',
    'COMPLETED': 'จบแล้ว',
    'CANCELLED': 'ยกเลิก',
  };
  static const _costLabels = {
    'FREE': 'ฟรี',
    'SPLIT_EQUALLY': 'หารเท่ากัน',
    'FIXED_PRICE': 'ราคาคงที่',
  };
  static const _months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  _Period _period = _Period.month;
  DateTimeRange? _custom;

  Map<String, dynamic>? _data;
  DateTimeRange? _loadedRange; // ช่วงเวลาที่ข้อมูลบนจอเป็นของ
  bool _loading = true; // โหลดครั้งแรก
  bool _refreshing = false; // โหลดซ้ำตอนเปลี่ยนช่วง (ยังโชว์ข้อมูลเดิม)
  String? _error;
  int _reqId = 0; // กันผลของคำขอเก่ามาทับของใหม่

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------------- ช่วงเวลา ----------------

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTimeRange get _range {
    final now = DateTime.now();
    final today = _dateOnly(now);
    switch (_period) {
      case _Period.today:
        return DateTimeRange(start: today, end: today);
      case _Period.week:
        // สัปดาห์เริ่มวันจันทร์ ถึงวันอาทิตย์
        final start = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 6)),
        );
      case _Period.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case _Period.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      case _Period.custom:
        return _custom ?? DateTimeRange(start: today, end: today);
    }
  }

  String _rangeLabel(DateTimeRange r) {
    final a = thaiDate(_ymd(r.start));
    final b = thaiDate(_ymd(r.end));
    return a == b ? a : '$a – $b';
  }

  Future<void> _selectPeriod(_Period p) async {
    if (p == _Period.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 2, 12, 31),
        initialDateRange: _custom ?? _range,
        helpText: 'เลือกช่วงวันที่',
        saveText: 'ตกลง',
      );
      if (picked == null || !mounted) return;
      if (picked.duration.inDays > 1095) {
        showSnack(context, 'เลือกช่วงเวลาได้ไม่เกิน 3 ปี', error: true);
        return;
      }
      setState(() {
        _custom = picked;
        _period = p;
      });
    } else {
      if (p == _period) return;
      setState(() => _period = p);
    }
    _load();
  }

  // ---------------- โหลดข้อมูล ----------------

  Future<void> _load() async {
    final id = ++_reqId;
    final range = _range;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final d = await ApiService.getAdminDashboard(
        Session.userId,
        from: _ymd(range.start),
        to: _ymd(range.end),
      );
      if (!mounted || id != _reqId) return;
      setState(() {
        _data = d;
        _loadedRange = range;
        _loading = false;
        _refreshing = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _reqId) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        if (_data == null) _error = e.message;
      });
      if (_data != null) showSnack(context, e.message, error: true);
    }
  }

  List<Map<String, dynamic>> _list(dynamic v) =>
      (v is List ? v : const []).map((e) => asMap(e)).toList();

  _Series _parseSeries(dynamic raw) {
    final m = asMap(raw);
    final bucket = m['bucket']?.toString() ?? 'day';
    final items = _list(m['items']);
    final now = DateTime.now();
    final today = _dateOnly(now);
    final r = _loadedRange;
    final todayInRange =
        r != null && !today.isBefore(r.start) && !today.isAfter(r.end);

    String todayKey;
    switch (bucket) {
      case 'hour':
        todayKey = now.hour.toString().padLeft(2, '0');
        break;
      case 'month':
        todayKey = _ymd(today).substring(0, 7);
        break;
      default:
        todayKey = _ymd(today);
    }

    final values = <int>[];
    final labels = <String>[];
    var highlight = -1;
    for (var i = 0; i < items.length; i++) {
      final key = items[i]['key']?.toString() ?? '';
      values.add(toInt(items[i]['count']));
      if (todayInRange && key == todayKey) highlight = i;
      if (bucket == 'hour') {
        labels.add('${int.tryParse(key) ?? ''}');
      } else if (bucket == 'month' && key.length >= 7) {
        final mo = int.tryParse(key.substring(5, 7)) ?? 1;
        labels.add(_months[(mo - 1).clamp(0, 11)]);
      } else if (key.length >= 10) {
        labels.add('${int.tryParse(key.substring(8, 10)) ?? ''}');
      } else {
        labels.add('');
      }
    }
    return _Series(bucket, values, labels, highlight);
  }

  String _bucketText(String bucket) {
    switch (bucket) {
      case 'hour':
        return 'รายชั่วโมง';
      case 'month':
        return 'รายเดือน';
      default:
        return 'รายวัน';
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('แดชบอร์ดผู้ดูแล'),
        backgroundColor: kSurface,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _refreshing ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodBar(),
          SizedBox(
            height: 3,
            child: _refreshing
                ? const LinearProgressIndicator(
                    color: kGreen,
                    backgroundColor: Colors.transparent,
                  )
                : null,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kGreen))
                : (_error != null && d == null)
                ? Center(
                    child: ErrorView(message: _error!, onRetry: _load),
                  )
                : _buildContent(d!),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBar() {
    final r = _loadedRange ?? _range;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in _Period.values) ...[
                  ChoiceChip(
                    avatar: p == _Period.custom
                        ? Icon(
                            Icons.date_range,
                            size: 16,
                            color: _period == p ? Colors.white : kInk,
                          )
                        : null,
                    label: Text(
                      _periodLabels[p]!,
                      style: TextStyle(
                        color: _period == p ? Colors.white : kInk,
                        fontWeight: _period == p
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: _period == p,
                    showCheckmark: false,
                    selectedColor: kInk,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _period == p ? kInk : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (_) => _selectPeriod(p),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _rangeLabel(r),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> d) {
    final t = asMap(d['totals']);
    final sports = _list(d['by_sport']);
    final events = _parseSeries(d['events_series']);
    final messages = _parseSeries(d['messages_series']);
    final statuses = _list(d['by_status']);
    final costs = _list(d['by_cost_type']);
    final hosts = _list(d['top_hosts']);
    final topRatedUsers = _list(d['top_rated_users']);
    final pendingEvents = _list(d['pending_events']);
    final hot = _list(d['hot_events']);

    final maxParticipants = sports.fold<int>(
      0,
      (m, s) => toInt(s['participants']) > m ? toInt(s['participants']) : m,
    );

    return RefreshIndicator(
      color: kGreen,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _Kpi(
                icon: Icons.groups_outlined,
                value: '${toInt(t['users'])}',
                label: 'สมาชิก (ทั้งระบบ)',
                sub: 'ยืนยันตัวตน ${toInt(t['verified_users'])} คน',
              ),
              _Kpi(
                icon: Icons.event_available_outlined,
                value: '${toInt(t['events'])}',
                label: 'กิจกรรมในช่วงนี้',
                sub: 'เปิดรับสมัคร ${toInt(t['upcoming_events'])}',
              ),
              _Kpi(
                icon: Icons.how_to_reg_outlined,
                value: '${toInt(t['participations'])}',
                label: 'การเข้าร่วมในช่วงนี้',
                sub:
                    'เต็มเฉลี่ย ${toDouble(t['avg_fill_rate']).toStringAsFixed(1)}%',
              ),
              _Kpi(
                icon: Icons.chat_bubble_outline,
                value: '${toInt(t['messages'])}',
                label: 'ข้อความแชทในช่วงนี้',
                sub: 'ทั้งหมด ${toInt(t['messages_total'])}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _pendingSummary(toInt(t['pending_events'])),
          const SizedBox(height: 16),
          _card(
            title: 'กิจกรรมค้างยืนยัน',
            subtitle:
                'เลยเวลาสิ้นสุดแล้วแต่ยังไม่ยืนยันเสร็จ • แสดงเก่าสุด 10 รายการ',
            child: pendingEvents.isEmpty
                ? _empty('ไม่มีกิจกรรมค้าง')
                : Column(
                    children: [
                      for (var i = 0; i < pendingEvents.length; i++)
                        _pendingEventRow(i + 1, pendingEvents[i]),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'ความนิยมของแต่ละกีฬา',
            subtitle: 'เรียงตามจำนวนผู้เข้าร่วมในช่วงที่เลือก',
            child: sports.isEmpty
                ? _empty('ยังไม่มีข้อมูล')
                : Column(
                    children: [
                      for (var i = 0; i < sports.length; i++)
                        _sportRow(i + 1, sports[i], maxParticipants),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'จำนวนกิจกรรม',
            subtitle: events.bucket == 'hour'
                ? 'รายชั่วโมง (ตามเวลาเริ่ม)'
                : '${_bucketText(events.bucket)} (ตามวันที่จัด)',
            child: _MiniBars(
              values: events.values,
              labels: events.labels,
              highlight: events.highlight,
              color: kBlue,
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'ข้อความแชท',
            subtitle: _bucketText(messages.bucket),
            child: _MiniBars(
              values: messages.values,
              labels: messages.labels,
              highlight: messages.highlight,
              color: kGreen,
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'สถานะและค่าใช้จ่ายของกิจกรรม',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สถานะ',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                statuses.isEmpty
                    ? const Text('-', style: TextStyle(color: Colors.grey))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in statuses)
                            _chip(
                              '${_statusLabels[s['status']] ?? s['status']} '
                              '${toInt(s['count'])}',
                            ),
                        ],
                      ),
                const SizedBox(height: 14),
                const Text(
                  'ค่าใช้จ่าย',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                costs.isEmpty
                    ? const Text('-', style: TextStyle(color: Colors.grey))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in costs)
                            _chip(
                              '${_costLabels[c['cost_type']] ?? c['cost_type']} '
                              '${toInt(c['count'])}',
                            ),
                        ],
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'ผู้จัดยอดนิยม',
            subtitle: 'เรียงตามจำนวนกิจกรรมที่จัดในช่วงที่เลือก',
            child: hosts.isEmpty
                ? _empty('ไม่มีผู้จัดในช่วงนี้')
                : Column(children: [for (final h in hosts) _hostRow(h)]),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'สมาชิกคะแนนสูงสุด',
            subtitle: 'เรียงคะแนนความน่าเชื่อถือจากมากไปน้อย • 10 อันดับแรก',
            child: topRatedUsers.isEmpty
                ? _empty('ยังไม่มีข้อมูลสมาชิก')
                : Column(
                    children: [
                      for (var i = 0; i < topRatedUsers.length; i++)
                        _trustRow(i + 1, topRatedUsers[i]),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'กิจกรรมยอดฮิต',
            subtitle: 'เรียงตามอัตราการเต็มในช่วงที่เลือก',
            child: hot.isEmpty
                ? _empty('ไม่มีกิจกรรมในช่วงนี้')
                : Column(children: [for (final e in hot) _hotRow(e)]),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    ),
  );

  Widget _pendingSummary(int count) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kDanger.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.pending_actions, color: kDanger),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'กิจกรรมค้าง',
                style: TextStyle(fontWeight: FontWeight.bold, color: kInk),
              ),
              Text(
                'เลยเวลาสิ้นสุด แต่ยังไม่ยืนยันเสร็จ',
                style: TextStyle(fontSize: 12, color: kNeutral),
              ),
            ],
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: kDanger,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    ),
  );

  Widget _pendingEventRow(int rank, Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: kDanger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(Icons.event_busy_outlined, color: kDanger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title']?.toString() ?? 'กิจกรรม',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${thaiDate(event['event_date']?.toString() ?? '')} '
                  'สิ้นสุด ${event['end_time'] ?? '-'} น. • '
                  'ผู้จัด ${event['host_name'] ?? 'ผู้ใช้งาน'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: kNeutral),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${toInt(event['current_participants'])} คน',
            style: const TextStyle(fontSize: 12, color: kNeutral),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
    ),
  );

  Widget _sportRow(int rank, Map<String, dynamic> s, int maxParticipants) {
    final participants = toInt(s['participants']);
    final value = maxParticipants > 0 ? participants / maxParticipants : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank == 1 ? kBlue : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  s['name']?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$participants คน • ${toInt(s['events'])} กิจกรรม',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0).toDouble(),
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: rank == 1 ? kBlue : kGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'อัตราเต็มเฉลี่ย ${toDouble(s['fill_rate']).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hostRow(Map<String, dynamic> h) {
    final name = h['name']?.toString() ?? 'ผู้ใช้งาน';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AvatarCircle(url: nonEmpty(h['avatar']), name: name, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'จัด ${toInt(h['events'])} กิจกรรม • ผู้เข้าร่วมรวม ${toInt(h['participants'])} คน',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, size: 15, color: kGreen),
          const SizedBox(width: 3),
          Text(
            toDouble(h['trust_score']).toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _trustRow(int rank, Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'ผู้ใช้งาน';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? kBlue : kNeutral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AvatarCircle(url: nonEmpty(user['avatar']), name: name, radius: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${toInt(user['total_completed_events'])} กิจกรรมที่เสร็จสิ้น',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 3),
          Text(
            toDouble(user['trust_score']).toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _hotRow(Map<String, dynamic> e) {
    final max = toInt(e['max_participants']);
    final cur = toInt(e['current_participants']);
    final value = max > 0 ? cur / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e['title']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$cur/$max คน',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${e['sport_name'] ?? ''} • ${thaiDate(e['event_date']?.toString() ?? '')}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              color: value >= 1 ? kDanger : kGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kInk,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// การ์ดตัวเลขสรุป
class _Kpi extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sub;

  const _Kpi({
    required this.icon,
    required this.value,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: kBlue, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kBlue, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// กราฟแท่งเรียบง่าย (ไม่พึ่งแพ็กเกจกราฟ)
/// แท่งมากกว่า 16 แท่งจะซ่อนตัวเลขบนแท่งและแสดงป้ายกำกับแบบเว้นระยะ
class _MiniBars extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final int highlight; // index ของแท่งที่เน้น (-1 = ไม่เน้น)
  final Color color;

  const _MiniBars({
    required this.values,
    required this.labels,
    required this.highlight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    final n = values.length;
    final maxV = values.fold<int>(0, (m, v) => v > m ? v : m);
    if (maxV == 0) {
      return const SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'ไม่มีข้อมูลในช่วงเวลานี้',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    final showCounts = n <= 16;
    final labelStep = n <= 16 ? 1 : (n / 8).ceil();
    final gap = n > 31 ? 0.5 : (n > 16 ? 1.0 : 2.0);

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < n; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gap),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showCounts && values[i] > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${values[i]}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      height: maxV == 0
                          ? 2.0
                          : (values[i] / maxV * 80).clamp(2.0, 80.0).toDouble(),
                      decoration: BoxDecoration(
                        color: i == highlight ? kInk : color.withAlpha(170),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 13,
                      child:
                          (i % labelStep == 0 || i == highlight) &&
                              i < labels.length
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: i == highlight ? kInk : Colors.grey,
                                  fontWeight: i == highlight
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
