import 'package:flutter/material.dart';

import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

/// แบนเนอร์กิจกรรม: ถ้าไม่มีรูปหรือโหลดไม่ได้ จะใช้พื้นไล่สีพร้อมไอคอนกีฬา
class EventBanner extends StatelessWidget {
  final EventItem event;
  final double height;

  const EventBanner({super.key, required this.event, this.height = 180});

  String? _defaultImageUrl(String sportName) {
    final sport = sportName.toLowerCase().trim();
    final String? fileName;

    if (sport.contains('badminton') || sport.contains('แบด')) {
      fileName = 'badminton.png';
    } else if (sport.contains('basketball') || sport.contains('บาส')) {
      fileName = 'basketball.png';
    } else if (sport.contains('cycling') ||
        sport.contains('cycl') ||
        sport.contains('จักรยาน') ||
        sport.contains('ปั่น')) {
      fileName = 'cycling.png';
    } else if (sport.contains('football') ||
        sport.contains('soccer') ||
        sport.contains('ฟุตบอล') ||
        sport.contains('ฟุตซอล')) {
      fileName = 'football.png';
    } else if (sport.contains('running') ||
        sport == 'run' ||
        sport.contains('วิ่ง')) {
      fileName = 'running.png';
    } else if (sport.contains('tennis') || sport.contains('เทนนิส')) {
      fileName = 'tennis.png';
    } else if (sport.contains('weight') ||
        sport.contains('gym') ||
        sport.contains('fitness') ||
        sport.contains('ฟิตเนส') ||
        sport.contains('เวท') ||
        sport.contains('ยกน้ำหนัก')) {
      fileName = 'weight.png';
    } else {
      return null;
    }

    return Uri.parse(kApiUrl).resolve('uploads/event_pic/$fileName').toString();
  }

  Widget _networkImage(String url, Widget fallback) => Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      );

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBlue, kInk],
        ),
      ),
      child: Icon(event.icon, size: 64, color: Colors.white54),
    );

    final defaultUrl = _defaultImageUrl(event.sportName);
    final customUrl = event.bannerUrl?.trim();
    final url = customUrl != null && customUrl.isNotEmpty
        ? customUrl
        : defaultUrl;
    if (url == null) return placeholder;

    final fallback = defaultUrl != null && defaultUrl != url
        ? _networkImage(defaultUrl, placeholder)
        : placeholder;
    return _networkImage(url, fallback);
  }
}

class EventCard extends StatelessWidget {
  final EventItem event;
  final VoidCallback onTap;

  /// แสดงป้าย "ผู้จัด" / "เข้าร่วมแล้ว" (ใช้ในหน้ากิจกรรมของฉัน)
  final bool showRole;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showRole = false,
  });

  String get _slotText {
    if (event.status != 'UPCOMING') return event.statusLabel;
    if (event.isFull) return 'เต็มแล้ว';
    if (event.remainingSlots <= 3) {
      return 'เหลือ ${event.remainingSlots} ที่สุดท้าย!';
    }
    return 'ว่าง ${event.remainingSlots} ที่';
  }

  @override
  Widget build(BuildContext context) {
    final unavailable = event.status != 'UPCOMING' || event.isFull;
    final progress = event.maxParticipants > 0
        ? (event.currentParticipants / event.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return Container(
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
          // 1. Banner + badges
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: EventBanner(event: event),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill(
                      text: event.statusLabel,
                      bgColor: unavailable ? kDanger : kGreen,
                      textColor: unavailable ? Colors.white : kInk,
                      showDot: true,
                    ),
                    Pill(
                      text: event.costLabel,
                      bgColor: Colors.white.withAlpha(230),
                      textColor: kInk,
                    ),
                    if (showRole && event.participantRole != null)
                      Pill(
                        text: event.participantRole == 'HOST'
                            ? 'ผู้จัด'
                            : 'เข้าร่วมแล้ว',
                        bgColor: kInk,
                        textColor: kBlue,
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  '${event.sportName} • ${event.locationName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),

          // 2. Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: kGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${event.dateLabel} • ${event.startTime} - ${event.endTime} น.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.locationName.isEmpty
                            ? 'ยังไม่ระบุสถานที่'
                            : event.locationName,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Host + capacity
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AvatarCircle(
                            url: event.host.avatarUrl,
                            name: event.host.displayName,
                            radius: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.host.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined,
                                        size: 13, color: kGreen),
                                    const SizedBox(width: 3),
                                    Text(
                                      'คะแนนความน่าเชื่อถือ ${event.host.trustScore.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _slotText,
                                style: TextStyle(
                                  color: unavailable
                                      ? Colors.grey
                                      : kGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'เข้าร่วมแล้ว ${event.currentParticipants}/${event.maxParticipants} คน',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade300,
                          color: kGreen,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Action
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    label: const Text(
                      'ดูรายละเอียดกิจกรรม',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
