import 'package:flutter/material.dart';

import 'api_service.dart';
import 'constants.dart';
import 'event_card.dart';
import 'event_detail_page.dart';
import 'models.dart';
import 'widgets.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const _sortLabels = {
    'time': 'เวลาเริ่ม',
    'slots': 'ที่ว่างมากสุด',
    'cost': 'ค่าใช้จ่าย',
  };

  final TextEditingController _searchCtrl = TextEditingController();

  List<SportCategory> _categories = [];
  List<EventItem> _events = [];

  int _selectedSportId = 0; // 0 = ทั้งหมด
  String _sort = 'time';
  bool _isLoading = true;
  String? _error;
  int _reqId = 0; // กันผลลัพธ์ของคำขอเก่ามาทับของใหม่

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (!mounted) return;
      setState(() => _categories = cats);
    } on ApiException {
      // หมวดหมู่โหลดไม่ได้ก็ยังใช้งานหน้านี้ต่อได้ (ตัวกรองจะมีแค่ "ทั้งหมด")
    }
  }

  Future<void> _loadEvents({bool silent = false}) async {
    final id = ++_reqId;
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final evs = await ApiService.getEvents(sportId: _selectedSportId);
      if (!mounted || id != _reqId) return;
      setState(() {
        _events = evs;
        _isLoading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _reqId) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  /// ค้นหาและเรียงลำดับฝั่งแอป (API ยังไม่รองรับ q / sort_by)
  List<EventItem> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _events.where((e) {
      if (e.status != 'UPCOMING') return false;
      if (q.isEmpty) return true;
      final hay = '${e.host.fullName} ${e.host.nickname ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();

    switch (_sort) {
      case 'slots':
        list.sort((a, b) => b.remainingSlots.compareTo(a.remainingSlots));
        break;
      case 'cost':
        list.sort((a, b) {
          final c = (a.costType == 'FREE' ? 0 : 1)
              .compareTo(b.costType == 'FREE' ? 0 : 1);
          return c != 0 ? c : a.costAmount.compareTo(b.costAmount);
        });
        break;
      default:
        list.sort((a, b) => a.startKey.compareTo(b.startKey));
    }
    return list;
  }

  Future<void> _openDetail(EventItem e) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailPage(eventId: e.id)),
    );
    if (mounted) _loadEvents(silent: true); // เผื่อเพิ่งเข้าร่วม จำนวนคนเปลี่ยน
  }

  @override
  Widget build(BuildContext context) {
    final events = _visible;

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadEvents(silent: true),
          color: kGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopHeader(),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildCategoryChips(),
                      const SizedBox(height: 20),
                      _buildSectionHeader(events.length),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: kGreen),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: ErrorView(message: _error!, onRetry: _loadEvents),
                )
              else if (events.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'ไม่พบกิจกรรมตามเงื่อนไขที่เลือก',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EventCard(
                          event: events[i],
                          onTap: () => _openDetail(events[i]),
                        ),
                      ),
                      childCount: events.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final user = Session.user;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: const Icon(Icons.fitness_center, color: kGreen, size: 24),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FitBuddy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
              Text(
                'Explore Events',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        AvatarCircle(
          url: user?.avatarUrl,
          name: user?.displayName ?? '?',
          radius: 20,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อกิจกรรม, สถานที่ หรือผู้จัด...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(_searchCtrl.clear),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = [const SportCategory(id: 0, nameTh: 'ทั้งหมด'), ..._categories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = chips[index];
          final isSelected = _selectedSportId == cat.id;
          return ChoiceChip(
            label: Text(
              cat.nameTh,
              style: TextStyle(
                color: isSelected ? Colors.white : kInk,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: kInk,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? kInk : Colors.grey.shade300),
            ),
            onSelected: (selected) {
              if (selected && !isSelected) {
                setState(() => _selectedSportId = cat.id);
                _loadEvents();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'กิจกรรมที่น่าสนใจ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kInk,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count รายการ',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          initialValue: _sort,
          onSelected: (v) => setState(() => _sort = v),
          itemBuilder: (_) => [
            for (final e in _sortLabels.entries)
              PopupMenuItem(value: e.key, child: Text(e.value)),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เรียง: ${_sortLabels[_sort]}',
                style: const TextStyle(
                  fontSize: 13,
                  color: kBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.sort, color: kBlue, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
