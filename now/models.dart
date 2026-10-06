import 'package:flutter/material.dart';

// ==========================================
// HELPERS
// ==========================================

/// คืน null ถ้าเป็น null / "" / "null"
String? nonEmpty(dynamic v) {
  final s = v?.toString().trim();
  if (s == null || s.isEmpty || s.toLowerCase() == 'null') return null;
  return s;
}

int toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
double toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

bool toBool(dynamic v) {
  final s = v?.toString().toLowerCase();
  return s == '1' || s == 'true';
}

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// "18:30:00" -> "18:30"
String hm(dynamic v) {
  final s = v?.toString() ?? '';
  return s.length >= 5 ? s.substring(0, 5) : s;
}

const _thMonths = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

/// "2026-09-20" -> "20 ก.ย. 2569"
String thaiDate(String ymd) {
  final p = ymd.split('-');
  if (p.length != 3) return ymd;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null || m < 1 || m > 12) return ymd;
  return '$d ${_thMonths[m - 1]} ${y + 543}';
}

String formatMoney(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

IconData sportIcon(String? iconName, String? nameTh) {
  final k = '${iconName ?? ''} ${nameTh ?? ''}'.toLowerCase();
  bool has(List<String> words) => words.any((w) => k.contains(w));

  if (has(['run', 'วิ่ง'])) return Icons.directions_run;
  if (has(['badminton', 'แบด', 'tennis', 'เทนนิส'])) return Icons.sports_tennis;
  if (has(['football', 'soccer', 'ฟุตบอล'])) return Icons.sports_soccer;
  if (has(['basket', 'บาส'])) return Icons.sports_basketball;
  if (has(['cycl', 'bike', 'ปั่น', 'จักรยาน'])) return Icons.directions_bike;
  if (has(['swim', 'ว่าย'])) return Icons.pool;
  if (has(['yoga', 'โยคะ'])) return Icons.self_improvement;
  if (has(['volley', 'วอลเลย์'])) return Icons.sports_volleyball;
  return Icons.fitness_center;
}

// ==========================================
// SESSION (เก็บผู้ใช้ที่ล็อกอินไว้ในหน่วยความจำ)
// ==========================================

class Session {
  static AppUser? user;
  static int get userId => user?.id ?? 0;
}

// ==========================================
// MODELS
// ==========================================

class AppUser {
  final int id;
  final String email;
  final String fullName;
  final String? nickname;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final String role;
  final double trustScore;
  final int totalCompletedEvents;
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.nickname,
    this.phone,
    this.bio,
    this.avatarUrl,
    this.role = 'USER',
    this.trustScore = 0,
    this.totalCompletedEvents = 0,
    this.isVerified = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: toInt(j['id']),
        email: j['email']?.toString() ?? '',
        fullName: nonEmpty(j['full_name']) ?? 'ผู้ใช้งาน',
        nickname: nonEmpty(j['nickname']),
        phone: nonEmpty(j['phone_number']),
        bio: nonEmpty(j['bio']),
        avatarUrl: nonEmpty(j['avatar_url']),
        role: nonEmpty(j['role']) ?? 'USER',
        trustScore: toDouble(j['trust_score']),
        totalCompletedEvents: toInt(j['total_completed_events']),
        isVerified: toBool(j['is_verified']),
      );

  String get displayName => nickname ?? fullName;
}

class SportCategory {
  final int id;
  final String nameTh;
  final String? nameEn;
  final String? iconName;
  final int eventCount;

  const SportCategory({
    required this.id,
    required this.nameTh,
    this.nameEn,
    this.iconName,
    this.eventCount = 0,
  });

  factory SportCategory.fromJson(Map<String, dynamic> j) => SportCategory(
        id: toInt(j['id']),
        nameTh: nonEmpty(j['name_th']) ?? '',
        nameEn: nonEmpty(j['name_en']),
        iconName: nonEmpty(j['icon_name']),
        eventCount: toInt(j['event_count']),
      );
}

class EventHost {
  final int id;
  final String fullName;
  final String? nickname;
  final String? avatarUrl;
  final double trustScore;

  const EventHost({
    required this.id,
    required this.fullName,
    this.nickname,
    this.avatarUrl,
    this.trustScore = 0,
  });

  factory EventHost.fromJson(Map<String, dynamic> j) => EventHost(
        id: toInt(j['id']),
        fullName: nonEmpty(j['name']) ?? 'ผู้ใช้งาน',
        nickname: nonEmpty(j['nickname']),
        avatarUrl: nonEmpty(j['avatar']),
        trustScore: toDouble(j['trust_score']),
      );

  String get displayName => nickname ?? fullName;
}

class EventItem {
  final int id;
  final String title;
  final String? description;
  final String sportName;
  final String? bannerUrl;
  final String status; // UPCOMING / ONGOING / COMPLETED / CANCELLED
  final String costType; // FREE / SPLIT_EQUALLY / FIXED_PRICE
  final double costAmount;
  final String eventDate; // YYYY-MM-DD
  final String startTime; // HH:MM
  final String endTime;
  final String locationName;
  final double latitude;
  final double longitude;
  final int maxParticipants;
  final int currentParticipants;
  final EventHost host;
  final String? participantRole; // มีเฉพาะจาก getMyEvents (HOST / MEMBER)

  const EventItem({
    required this.id,
    required this.title,
    this.description,
    required this.sportName,
    this.bannerUrl,
    required this.status,
    required this.costType,
    required this.costAmount,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    this.latitude = 0,
    this.longitude = 0,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.host,
    this.participantRole,
  });

  /// รองรับทั้งรูปแบบของ getEvents (host เป็น object)
  /// และ getEventDetail (host_name, host_nickname... แบนราบ)
  factory EventItem.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> hostJson = j['host'] is Map
        ? asMap(j['host'])
        : <String, dynamic>{
            'id': j['host_id'],
            'name': j['host_name'],
            'nickname': j['host_nickname'],
            'avatar': j['host_avatar'],
            'trust_score': j['host_trust_score'],
          };

    return EventItem(
      id: toInt(j['id']),
      title: j['title']?.toString() ?? '',
      description: nonEmpty(j['description']),
      sportName: nonEmpty(j['sport_name']) ?? 'กีฬา',
      bannerUrl: nonEmpty(j['banner_image_url']),
      status: nonEmpty(j['status']) ?? 'UPCOMING',
      costType: nonEmpty(j['cost_type']) ?? 'FREE',
      costAmount: toDouble(j['cost_amount']),
      eventDate: j['event_date']?.toString() ?? '',
      startTime: hm(j['start_time']),
      endTime: hm(j['end_time']),
      locationName: j['location_name']?.toString() ?? '',
      latitude: toDouble(j['latitude']),
      longitude: toDouble(j['longitude']),
      maxParticipants: toInt(j['max_participants']),
      currentParticipants: toInt(j['current_participants']),
      host: EventHost.fromJson(hostJson),
      participantRole: nonEmpty(j['participant_role']),
    );
  }

  int get remainingSlots => maxParticipants - currentParticipants;
  bool get isFull => maxParticipants > 0 && currentParticipants >= maxParticipants;
  bool get canJoin => status == 'UPCOMING' && !isFull;
  String get startKey => '$eventDate $startTime';
  IconData get icon => sportIcon(null, sportName);

  /// มีหมุดที่ผู้จัดปักไว้จริงหรือไม่
  /// (ไม่นับ 0,0 และพิกัดเริ่มต้นกรุงเทพฯ ที่ api.php ใส่ให้เมื่อไม่ได้ส่งพิกัดมา)
  bool get hasPin {
    if (latitude == 0 && longitude == 0) return false;
    final isApiDefault = (latitude - 13.736717).abs() < 0.000001 &&
        (longitude - 100.523186).abs() < 0.000001;
    return !isApiDefault;
  }

  EventItem withRole(String role) => EventItem(
        id: id,
        title: title,
        description: description,
        sportName: sportName,
        bannerUrl: bannerUrl,
        status: status,
        costType: costType,
        costAmount: costAmount,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        maxParticipants: maxParticipants,
        currentParticipants: currentParticipants,
        host: host,
        participantRole: role,
      );

  String get statusLabel {
    switch (status) {
      case 'UPCOMING':
        return isFull ? 'เต็มแล้ว' : 'เปิดรับสมัคร';
      case 'ONGOING':
        return 'กำลังจัดกิจกรรม';
      case 'COMPLETED':
        return 'จบแล้ว';
      case 'CANCELLED':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  String get costLabel {
    switch (costType) {
      case 'FREE':
        return 'ฟรี';
      case 'SPLIT_EQUALLY':
        return costAmount > 0
            ? 'หารเท่ากัน ~฿${formatMoney(costAmount)}'
            : 'หารค่าใช้จ่ายเท่ากัน';
      case 'FIXED_PRICE':
        return '฿${formatMoney(costAmount)} / คน';
      default:
        return costType;
    }
  }

  String get dateLabel => thaiDate(eventDate);
}

class Participant {
  final int userId;
  final String name;
  final String? nickname;
  final String? avatarUrl;
  final String role; // HOST / MEMBER

  const Participant({
    required this.userId,
    required this.name,
    this.nickname,
    this.avatarUrl,
    required this.role,
  });

  factory Participant.fromJson(Map<String, dynamic> j) => Participant(
        userId: toInt(j['user_id']),
        name: nonEmpty(j['name']) ?? 'ผู้ใช้งาน',
        nickname: nonEmpty(j['nickname']),
        avatarUrl: nonEmpty(j['avatar']),
        role: nonEmpty(j['participant_role']) ?? 'MEMBER',
      );

  String get displayName => nickname ?? name;
  bool get isHost => role == 'HOST';
}

class EventDetail {
  final EventItem event;
  final List<Participant> participants;
  final String? myTicketCode;

  const EventDetail({
    required this.event,
    required this.participants,
    this.myTicketCode,
  });

  factory EventDetail.fromJson(Map<String, dynamic> j) {
    final parts = j['participants'];
    return EventDetail(
      event: EventItem.fromJson(j),
      participants: (parts is List ? parts : const [])
          .map((e) => Participant.fromJson(asMap(e)))
          .toList(),
      myTicketCode: nonEmpty(j['my_ticket_code']),
    );
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String? avatarUrl;
  final String type; // TEXT / LOCATION
  final String content;
  final double? lat;
  final double? lng;
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.avatarUrl,
    required this.type,
    required this.content,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: toInt(j['id']),
        senderId: toInt(j['sender_id']),
        senderName: nonEmpty(j['sender_name']) ?? 'ผู้ใช้งาน',
        avatarUrl: nonEmpty(j['avatar']),
        type: nonEmpty(j['message_type']) ?? 'TEXT',
        content: j['content']?.toString() ?? '',
        lat: j['lat'] == null ? null : toDouble(j['lat']),
        lng: j['lng'] == null ? null : toDouble(j['lng']),
        createdAt: j['created_at']?.toString() ?? '',
      );

  /// "2026-09-20 18:30:12" -> "18:30"
  String get timeLabel =>
      createdAt.length >= 16 ? createdAt.substring(11, 16) : '';
}