import 'dart:async';
import 'dart:convert';
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

int userIdOf(Map<String, dynamic> user) => toInt(user['id']);

class ApiService {
  static const _timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> _send(
    String action, {
    Map<String, String>? query,
    Map<String, String>? body,
  }) async {
    final uri = Uri.parse(kApiUrl).replace(queryParameters: {'action': action, ...?query});

    final res = body == null
        ? await http.get(uri).timeout(_timeout)
        : await http.post(uri, body: body).timeout(_timeout);

    var text = utf8.decode(res.bodyBytes, allowMalformed: true).trim();
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final map = Map<String, dynamic>.from(jsonDecode(text));
    if (map['success'] != true) {
      throw ApiException(map['message']?.toString() ?? 'เกิดข้อผิดพลาด', res.statusCode);
    }
    return map;
  }

  static Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('เชื่อมต่อเซิร์ฟเวอร์หมดเวลา กรุณาลองใหม่');
    } catch (_) {
      throw const ApiException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบอินเทอร์เน็ต');
    }
  }

  static List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
      (data is List ? data : const []).map((e) => f(asMap(e))).toList();

  static Future<Map<String, dynamic>> login(String email, String password) =>
      _guard(() async {
        final res = await _send('login', body: {'email': email.trim(), 'password': password});
        return asMap(res['data']);
      });

  static Future<int> register({
    required String fullName,
    required String nickname,
    required String phone,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final res = await _send('register', body: {
          'full_name': fullName.trim(),
          'nickname': nickname.trim(),
          'phone_number': phone.trim(),
          'email': email.trim(),
          'password': password,
          'pdpa_consent': '1',
        });
        return toInt(res['user_id']);
      });

  static Future<List<SportCategory>> getCategories() => _guard(() async {
        final res = await _send('getCategories');
        return _list(res['data'], SportCategory.fromJson);
      });

  static Future<List<EventItem>> getEvents({int sportId = 0}) => _guard(() async {
        final res = await _send('getEvents', query: sportId > 0 ? {'sport_id': '$sportId'} : null);
        return _list(res['data'], EventItem.fromJson);
      });

  static Future<List<EventItem>> getMyEvents(int userId) => _guard(() async {
        final res = await _send('getMyEvents', query: {'user_id': '$userId'});
        return _list(res['data'], EventItem.fromJson);
      });

  static Future<EventDetail> getEventDetail(int id, {int userId = 0}) => _guard(() async {
        final res = await _send('getEventDetail', query: {
          'id': '$id',
          if (userId > 0) 'user_id': '$userId',
        });
        return EventDetail.fromJson(asMap(res['data']));
      });

  static Future<Map<String, dynamic>> getAdminDashboard() => _guard(() async {
        final res = await _send('getAdminDashboard');
        return asMap(res['data']);
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
  }) =>
      _guard(() async {
        final res = await _send('createEvent', body: {
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
        });
        return toInt(res['event_id']);
      });

  static Future<String> joinEvent(int eventId, int userId) => _guard(() async {
        final res = await _send('joinEvent', body: {'event_id': '$eventId', 'user_id': '$userId'});
        return res['ticket_code']?.toString() ?? '';
      });

  static Future<List<ChatMessage>> getChatMessages(int eventId, {int afterId = 0}) => _guard(() async {
        final res = await _send('getChatMessages', query: {'event_id': '$eventId', 'after_id': '$afterId'});
        return _list(res['data'], ChatMessage.fromJson);
      });

  static Future<void> sendMessage(int eventId, int senderId, String content) => _guard(() async {
        await _send('sendMessage', body: {
          'event_id': '$eventId',
          'sender_id': '$senderId',
          'content': content,
          'message_type': 'TEXT',
        });
      });

  static Future<Map<String, dynamic>> updateProfile(
    int userId, {
    String? fullName,
    String? nickname,
    String? bio,
  }) =>
      _guard(() async {
        final body = <String, String>{'user_id': '$userId'};
        if (fullName != null) body['full_name'] = fullName;
        if (nickname != null) body['nickname'] = nickname;
        if (bio != null) body['bio'] = bio;
        final res = await _send('updateProfile', body: body);
        return asMap(res['data']);
      });

  static Future<Map<String, dynamic>> changePhone(int userId, String phoneNumber) => _guard(() async {
        final res = await _send('changePhone', body: {'user_id': '$userId', 'phone_number': phoneNumber});
        return asMap(res['data']);
      });

  static Future<void> changePassword(
    int userId, {
    required String currentPassword,
    required String newPassword,
  }) =>
      _guard(() async {
        await _send('changePassword', body: {
          'user_id': '$userId',
          'current_password': currentPassword,
          'new_password': newPassword,
        });
      });

  static Future<Map<String, dynamic>> uploadAvatar(
    int userId, {
    required List<int> bytes,
    String filename = 'avatar.jpg',
  }) =>
      _guard(() async {
        final request = http.MultipartRequest('POST', Uri.parse('$kApiUrl?action=uploadAvatar'))
          ..fields['user_id'] = '$userId'
          ..files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: filename.isEmpty ? 'avatar.jpg' : filename));

        final streamed = await request.send().timeout(_timeout);
        final res = await http.Response.fromStream(streamed);

        var text = utf8.decode(res.bodyBytes, allowMalformed: true).trim();
        final map = Map<String, dynamic>.from(jsonDecode(text));
        return asMap(map['data']);
      });
}