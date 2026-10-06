import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bmi_record.dart';

class DBHelper {
  static const String baseUrl = "https://std.mcs.psu.ac.th/6620310242/html/BMI/api_bmi.php";

  static Future<Map<String, dynamic>?> createRecord({
    required String name,
    required double heightCm,
    required double weightKg,
  }) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "action": "create_record",
        "name": name,
        "height_cm": heightCm.toString(),
        "weight_kg": weightKg.toString(),
      },
    ).timeout(const Duration(seconds: 10));

    final data = json.decode(res.body);
    if (data['status'] == 'success') {
      return {
        "id": data['id'],
        "bmi": double.parse(data['bmi'].toString()),
        "category": data['category'],
      };
    }
    return null;
  }

  static Future<List<BmiRecord>> getRecords() async {
    final res = await http.get(Uri.parse("$baseUrl?action=read_records"))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((json) => BmiRecord.fromJson(json)).toList();
    }
    throw Exception('read_records failed (${res.statusCode})');
  }

  static Future<bool> deleteRecord(int id) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {"action": "delete_record", "id": id.toString()},
    ).timeout(const Duration(seconds: 10));

    final data = json.decode(res.body);
    return data['status'] == 'success';
  }
}