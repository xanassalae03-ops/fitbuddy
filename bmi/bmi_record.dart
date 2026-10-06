class BmiRecord {
  final int id;
  final String name;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final String category;
  final String createdAt;

  BmiRecord({
    required this.id,
    required this.name,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.category,
    required this.createdAt,
  });

  factory BmiRecord.fromJson(Map<String, dynamic> json) {
    return BmiRecord(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      heightCm: double.parse(json['height_cm'].toString()),
      weightKg: double.parse(json['weight_kg'].toString()),
      bmi: double.parse(json['bmi'].toString()),
      category: json['category'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}