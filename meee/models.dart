import 'package:flutter/material.dart';

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

int toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double toDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

String toStr(dynamic v) => v == null ? '' : v.toString();

String? nonEmpty(dynamic v) {
  final s = v?.toString().trim();
  if (s == null || s.isEmpty || s.toLowerCase() == 'null') return null;
  return s;
}

const _thMonths = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

String thaiDate(String ymd) {
  final p = ymd.split('-');
  if (p.length != 3) return ymd;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null || m < 1 || m > 12) return ymd;
  return '$d ${_thMonths[m - 1]} ${y + 543}';
}

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

class AppUser {
  final int id;
  final String email;
  final String fullName;
  final String nickname;
  final String phoneNumber;
  final String bio;
  final String avatarUrl;
  final String role;
  final double trustScore;
  final int totalCompletedEvents;
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.nickname,
    required this.phoneNumber,
    required this.bio,
    required this.avatarUrl,
    required this.role,
    required this.trustScore,
    required this.totalCompletedEvents,
    required this.isVerified,
  });

  String get displayName => nickname.isEmpty ? fullName : '$fullName ($nickname)';

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final v = j['is_verified'];
    return AppUser(
      id: toInt(j['id']),
      email: toStr(j['email']),
      fullName: toStr(j['full_name']),
      nickname: toStr(j['nickname']),
      phoneNumber: toStr(j['phone_number']),
      bio: toStr(j['bio']),
      avatarUrl: toStr(j['avatar_url']),
      role: toStr(j['role']),
      trustScore: toDouble(j['trust_score']),
      totalCompletedEvents: toInt(j['total_completed_events']),
      isVerified: v == true || v == 1 || v == '1',
    );
  }
}

class SportCategory {
  final int id;
  final String nameTh;
  final String nameEn;
  final String iconName;
  final int eventCount;

  const SportCategory({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.iconName,
    required this.eventCount,
  });

  factory SportCategory.fromJson(Map<String, dynamic> j) => SportCategory(
        id: toInt(j['id']),
        nameTh: toStr(j['name_th']),
        nameEn: toStr(j['name_en']),
        iconName: toStr(j['icon_name']),
        eventCount: toInt(j['event_count']),
      );
}

class HostInfo {
  final int id;
  final String name;
  final String nickname;
  final String avatar;
  final double trustScore;

  const HostInfo({
    required this.id,
    required this.name,
    required this.nickname,
    required this.avatar,
    required this.trustScore,
  });

  String get displayName => nickname.isEmpty ? name : '$name ($nickname)';

  factory HostInfo.fromJson(Map<String, dynamic> j) => HostInfo(
        id: toInt(j['id']),
        name: toStr(j['name']),
        nickname: toStr(j['nickname']),
        avatar: toStr(j['avatar']),
        trustScore: toDouble(j['trust_score']),
      );
}

class EventItem {
  final int id;
  final String title;
  final String description;
  final String locationName;
  final double latitude;
  final double longitude;
  final String eventDate;
  final String startTime;
  final String endTime;
  final int maxParticipants;
  final int currentParticipants;
  final String costType;
  final double costAmount;
  final String status;
  final String bannerImageUrl;
  final String sportName;
  final HostInfo host;
  final String? role;

  const EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.costType,
    required this.costAmount,
    required this.status,
    required this.bannerImageUrl,
    required this.sportName,
    required this.host,
    this.role,
  });

  int get remainingSlots => maxParticipants - currentParticipants;
  bool get isFull => maxParticipants > 0 && currentParticipants >= maxParticipants;
  bool get canJoin => status == 'UPCOMING' && !isFull;
  String get startKey => '$eventDate $startTime';
  IconData get icon => sportIcon(null, sportName);

  bool get hasPin {
    if (latitude == 0 && longitude == 0) return false;
    final isDefault = (latitude - 13.736717).abs() < 0.000001 &&
        (longitude - 100.523186).abs() < 0.000001;
    return !isDefault;
  }

  String get statusLabel {
    switch (status) {
      case 'UPCOMING': return isFull ? 'เต็มแล้ว' : 'เปิดรับสมัคร';
      case 'ONGOING': return 'กำลังจัดกิจกรรม';
      case 'COMPLETED': return 'จบแล้ว';
      case 'CANCELLED': return 'ยกเลิก';
      default: return status;
    }
  }

  String get costLabel {
    switch (costType) {
      case 'FREE': return 'ฟรี';
      case 'SPLIT_EQUALLY': return costAmount > 0 ? 'หารเท่ากัน ~฿${costAmount.toStringAsFixed(0)}' : 'หารเท่ากัน';
      case 'FIXED_PRICE': return '฿${costAmount.toStringAsFixed(0)} / คน';
      default: return costType;
    }
  }

  EventItem withRole(String newRole) => EventItem(
        id: id,
        title: title,
        description: description,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        maxParticipants: maxParticipants,
        currentParticipants: currentParticipants,
        costType: costType,
        costAmount: costAmount,
        status: status,
        bannerImageUrl: bannerImageUrl,
        sportName: sportName,
        host: host,
        role: newRole,
      );

  factory EventItem.fromJson(Map<String, dynamic> j) {
    final hostJson = j['host'] is Map
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
      title: toStr(j['title']),
      description: toStr(j['description']),
      locationName: toStr(j['location_name']),
      latitude: toDouble(j['latitude']),
      longitude: toDouble(j['longitude']),
      eventDate: toStr(j['event_date']),
      startTime: toStr(j['start_time']).length >= 5 ? toStr(j['start_time']).substring(0, 5) : toStr(j['start_time']),
      endTime: toStr(j['end_time']).length >= 5 ? toStr(j['end_time']).substring(0, 5) : toStr(j['end_time']),
      maxParticipants: toInt(j['max_participants']),
      currentParticipants: toInt(j['current_participants']),
      costType: toStr(j['cost_type']),
      costAmount: toDouble(j['cost_amount']),
      status: toStr(j['status']),
      bannerImageUrl: toStr(j['banner_image_url']),
      sportName: toStr(j['sport_name'] ?? j['sport_name_th']),
      host: HostInfo.fromJson(hostJson),
      role: j['participant_role'] == null ? null : toStr(j['participant_role']),
    );
  }
}

class ParticipantInfo {
  final int userId;
  final String name;
  final String nickname;
  final String avatar;
  final String participantRole;

  const ParticipantInfo({
    required this.userId,
    required this.name,
    required this.nickname,
    required this.avatar,
    required this.participantRole,
  });

  String get displayName => nickname.isEmpty ? name : '$name ($nickname)';
  bool get isHost => participantRole == 'HOST';

  factory ParticipantInfo.fromJson(Map<String, dynamic> j) => ParticipantInfo(
        userId: toInt(j['user_id']),
        name: toStr(j['name']),
        nickname: toStr(j['nickname']),
        avatar: toStr(j['avatar']),
        participantRole: toStr(j['participant_role']),
      );
}

class EventDetail {
  final EventItem event;
  final List<ParticipantInfo> participants;
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
          .map((e) => ParticipantInfo.fromJson(asMap(e)))
          .toList(),
      myTicketCode: nonEmpty(j['my_ticket_code']),
    );
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String avatar;
  final String messageType;
  final String content;
  final double? lat;
  final double? lng;
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.avatar,
    required this.messageType,
    required this.content,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  String get timeLabel =>
      createdAt.length >= 16 ? createdAt.substring(11, 16) : '';

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: toInt(j['id']),
        senderId: toInt(j['sender_id']),
        senderName: toStr(j['sender_name']),
        avatar: toStr(j['avatar']),
        messageType: toStr(j['message_type']),
        content: toStr(j['content']),
        lat: j['lat'] == null ? null : toDouble(j['lat']),
        lng: j['lng'] == null ? null : toDouble(j['lng']),
        createdAt: toStr(j['created_at']),
      );
}