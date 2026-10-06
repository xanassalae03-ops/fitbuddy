import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 15);

  static int userIdOf(Map<String, dynamic> user) => toInt(user['id']);

  /// ยิง request แล้วคืน JSON ทั้งก้อน (ถ้า success != true จะโยน ApiException
  /// พร้อมข้อความที่ PHP ส่งมา)
  static Future<Map<String, dynamic>> _send(
    String action, {
    Map<String, String>? query,
    Map<String, String>? body,
  }) async {
    final uri = Uri.parse(
      kApiUrl,
    ).replace(queryParameters: {'action': action, ...?query});

    final res = body == null
        ? await http.get(uri).timeout(_timeout)
        : await http.post(uri, body: body).timeout(_timeout);

    var text = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (text.startsWith('\uFEFF')) text = text.substring(1); // ตัด BOM
    text = text.trim();

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      debugPrint(
        '[API $action] HTTP ${res.statusCode} ไม่ใช่ JSON: '
        '${text.length > 300 ? text.substring(0, 300) : text}',
      );
      throw ApiException(
        'เซิร์ฟเวอร์ตอบกลับไม่ใช่ JSON (HTTP ${res.statusCode})',
        res.statusCode,
      );
    }

    if (decoded is! Map) {
      throw ApiException(
        'รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง',
        res.statusCode,
      );
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['success'] != true) {
      throw ApiException(
        map['message']?.toString() ?? 'เกิดข้อผิดพลาด (HTTP ${res.statusCode})',
        res.statusCode,
      );
    }
    return map;
  }

  /// แปลง error ทุกชนิดให้เป็น ApiException ที่มีข้อความอ่านรู้เรื่อง
  static Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('เชื่อมต่อเซิร์ฟเวอร์หมดเวลา กรุณาลองใหม่');
    } on http.ClientException {
      throw const ApiException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบอินเทอร์เน็ตหรือ CORS ของ API',
      );
    } catch (e) {
      debugPrint('[API] parse error: $e');
      throw const ApiException('ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }
  }

  static List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
      (data is List ? data : const []).map((e) => f(asMap(e))).toList();

  // ---------------- Auth ----------------

  static Future<AppUser> login(String email, String password) =>
      _guard(() async {
        final res = await _send(
          'login',
          body: {'email': email.trim(), 'password': password},
        );
        return AppUser.fromJson(asMap(res['data']));
      });

  static Future<int> register({
    required String fullName,
    required String nickname,
    required String phone,
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await _send(
      'register',
      body: {
        'full_name': fullName.trim(),
        'nickname': nickname.trim(),
        'phone_number': phone.trim(),
        'email': email.trim(),
        'password': password,
        'pdpa_consent': '1',
      },
    );
    return toInt(res['user_id']);
  });

  // ---------------- Categories / Events ----------------

  static Future<List<SportCategory>> getCategories() => _guard(() async {
    final res = await _send('getCategories');
    return _list(res['data'], SportCategory.fromJson);
  });

  static Future<List<EventItem>> getEvents({
    int sportId = 0,
    bool upcomingOnly = false,
  }) => _guard(() async {
    final query = <String, String>{
      if (sportId > 0) 'sport_id': '$sportId',
      if (upcomingOnly) 'status': 'UPCOMING',
    };
    final res = await _send('getEvents', query: query.isEmpty ? null : query);
    return _list(res['data'], EventItem.fromJson);
  });

  /// กิจกรรมที่ผู้ใช้เป็นผู้จัดหรือเข้าร่วม
  /// ถ้า api.php มี action getMyEvents จะใช้อันนั้น (เร็วกว่า)
  /// ถ้าไม่มี (Invalid action) จะประกอบเองจาก getEvents + getEventDetail
  static Future<List<EventItem>> getMyEvents(int userId) => _guard(() async {
    try {
      final res = await _send('getMyEvents', query: {'user_id': '$userId'});
      return _list(res['data'], EventItem.fromJson);
    } on ApiException catch (e) {
      if (e.statusCode == 404 && e.message == 'Invalid action') {
        return _getMyEventsFallback(userId);
      }
      rethrow;
    }
  });

  static Future<List<EventItem>> _getMyEventsFallback(int userId) async {
    final res = await _send('getEvents');
    final all = _list(res['data'], EventItem.fromJson);

    final mine = <EventItem>[];
    final others = <EventItem>[];
    for (final e in all) {
      if (e.host.id == userId) {
        mine.add(e.withRole('HOST'));
      } else {
        others.add(e);
      }
    }

    // เช็กทีละ 5 กิจกรรมพร้อมกัน ว่าเราอยู่ในรายชื่อผู้เข้าร่วมหรือไม่
    const batch = 5;
    for (var i = 0; i < others.length; i += batch) {
      final chunk = others.sublist(
        i,
        i + batch > others.length ? others.length : i + batch,
      );
      final results = await Future.wait(
        chunk.map((e) async {
          try {
            final r = await _send(
              'getEventDetail',
              query: {'id': '${e.id}', 'user_id': '$userId'},
            );
            final d = EventDetail.fromJson(asMap(r['data']));
            final joined =
                d.myTicketCode != null ||
                d.participants.any((p) => p.userId == userId);
            return joined ? e.withRole('MEMBER') : null;
          } catch (_) {
            return null; // กิจกรรมไหนโหลดไม่ได้ ข้ามไป
          }
        }),
      );
      mine.addAll(results.whereType<EventItem>());
    }

    mine.sort((a, b) => a.startKey.compareTo(b.startKey));
    return mine;
  }

  static Future<EventDetail> getEventDetail(int id, {int userId = 0}) =>
      _guard(() async {
        final res = await _send(
          'getEventDetail',
          query: {'id': '$id', if (userId > 0) 'user_id': '$userId'},
        );
        return EventDetail.fromJson(asMap(res['data']));
      });

  static Future<int> createEvent({
    required int hostId,
    required int sportId,
    required String title,
    required String description,
    required String locationName,
    required double latitude,
    required double longitude,
    required String eventDate,
    required String startTime,
    required String endTime,
    required int maxParticipants,
    required String costType,
    required double costAmount,
  }) => _guard(() async {
    final res = await _send(
      'createEvent',
      body: {
        'host_id': '$hostId',
        'sport_id': '$sportId',
        'title': title.trim(),
        'description': description.trim(),
        'location_name': locationName.trim(),
        'latitude': latitude.toStringAsFixed(7),
        'longitude': longitude.toStringAsFixed(7),
        'event_date': eventDate,
        'start_time': startTime,
        'end_time': endTime,
        'max_participants': '$maxParticipants',
        'cost_type': costType,
        'cost_amount': '$costAmount',
      },
    );
    return toInt(res['event_id']);
  });

  /// คืน ticket_code
  static Future<String> joinEvent(int eventId, int userId) => _guard(() async {
    final res = await _send(
      'joinEvent',
      body: {'event_id': '$eventId', 'user_id': '$userId'},
    );
    return res['ticket_code']?.toString() ?? '';
  });

  static Future<void> completeEvent(int eventId, int hostId) =>
      _guard(() async {
        await _send(
          'completeEvent',
          body: {'event_id': '$eventId', 'user_id': '$hostId'},
        );
      });

  static Future<void> submitEventReview({
    required int eventId,
    required int reviewerId,
    required int revieweeId,
    required int rating,
    required String comment,
  }) => _guard(() async {
    await _send(
      'submitEventReview',
      body: {
        'event_id': '$eventId',
        'reviewer_id': '$reviewerId',
        'reviewee_id': '$revieweeId',
        'rating': '$rating',
        'comment': comment.trim(),
      },
    );
  });

  // ---------------- Chat ----------------

  static Future<List<ChatMessage>> getChatMessages(
    int eventId, {
    int afterId = 0,
  }) => _guard(() async {
    final res = await _send(
      'getChatMessages',
      query: {'event_id': '$eventId', 'after_id': '$afterId'},
    );
    return _list(res['data'], ChatMessage.fromJson);
  });

  static Future<void> sendMessage(int eventId, int senderId, String content) =>
      _guard(() async {
        await _send(
          'sendMessage',
          body: {
            'event_id': '$eventId',
            'sender_id': '$senderId',
            'content': content,
            'message_type': 'TEXT',
          },
        );
      });

  // ---------------- Admin ----------------

  /// ข้อมูลแดชบอร์ดผู้ดูแล (ต้องเป็น role ADMIN)
  /// [from] / [to] รูปแบบ YYYY-MM-DD (รวมทั้งสองวัน)
  static Future<Map<String, dynamic>> getAdminDashboard(
    int adminId, {
    required String from,
    required String to,
  }) => _guard(() async {
    final res = await _send(
      'getAdminDashboard',
      query: {'admin_id': '$adminId', 'from': from, 'to': to},
    );
    return asMap(res['data']);
  });

  // ---------------- Profile ----------------

  static Map<String, dynamic> _profileData(Map<String, dynamic> json) =>
      asMap(json['data']);

  static Future<Map<String, dynamic>> updateProfile(
    int userId, {
    String? fullName,
    String? nickname,
    String? bio,
  }) => _guard(() async {
    final body = <String, String>{'user_id': '$userId'};
    if (fullName != null) body['full_name'] = fullName;
    if (nickname != null) body['nickname'] = nickname;
    if (bio != null) body['bio'] = bio;
    return _profileData(await _send('updateProfile', body: body));
  });

  static Future<Map<String, dynamic>> changePhone(
    int userId,
    String phoneNumber,
  ) => _guard(() async {
    final res = await _send(
      'changePhone',
      body: {'user_id': '$userId', 'phone_number': phoneNumber},
    );
    return _profileData(res);
  });

  static Future<void> changePassword(
    int userId, {
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    await _send(
      'changePassword',
      body: {
        'user_id': '$userId',
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  });

  static Future<Map<String, dynamic>> uploadAvatar(
    int userId, {
    required List<int> bytes,
    String filename = 'avatar.jpg',
  }) => _guard(() async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$kApiUrl?action=uploadAvatar'))
          ..fields['user_id'] = '$userId'
          ..files.add(
            http.MultipartFile.fromBytes(
              'avatar',
              bytes,
              filename: filename.isEmpty ? 'avatar.jpg' : filename,
            ),
          );

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    var text = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    text = text.trim();

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw ApiException(
        'เซิร์ฟเวอร์ตอบกลับไม่ใช่ JSON (HTTP ${response.statusCode})',
        response.statusCode,
      );
    }
    if (decoded is! Map) {
      throw ApiException(
        'รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง',
        response.statusCode,
      );
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['success'] != true) {
      throw ApiException(
        map['message']?.toString() ??
            'เกิดข้อผิดพลาด (HTTP ${response.statusCode})',
        response.statusCode,
      );
    }
    return _profileData(map);
  });
}
