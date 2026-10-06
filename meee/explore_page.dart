import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'event_card.dart';
import 'event_detail_page.dart';
import 'models.dart';

class ExplorePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ExplorePage({super.key, required this.user});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<SportCategory> _categories = [];
  final List<EventItem> _events = [];
  int _selectedSportId = 0;
  bool _isLoading = true;

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
      setState(() {
        _categories.clear();
        _categories.addAll(cats);
      });
    } catch (_) {}
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final evs = await ApiService.getEvents(sportId: _selectedSportId);
      if (!mounted) return;
      setState(() {
        _events.clear();
        _events.addAll(evs);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          color: kGreenDark,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const AuthLogo(size: 40, glow: false),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ค้นหากิจกรรม',
                      style: TextStyle(
                        color: kNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  UserAvatar(
                    url: widget.user['avatar_url']?.toString(),
                    size: 40,
                    ring: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                decoration: authInputDecoration(
                  icon: Icons.search,
                  hint: 'ค้นหากิจกรรม...',
                  fill: Colors.white,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: kGreen),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => EventCard(
                    event: _events[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(
                          eventId: _events[i].id,
                          currentUser: widget.user,
                        ),
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