import 'dart:convert';
import 'package:flutter/services.dart';


class AdviceRepository {
  final Map<String, dynamic> _data;

  AdviceRepository(this._data);

  static Future<AdviceRepository> loadFromAssets(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AdviceRepository(map);
  }

  Advice? getAdvice(String label) {
    final v = _data[label];
    if (v is! Map<String, dynamic>) return null;
    return Advice.fromMap(v);
  }
}


class Advice {
  final String title;
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> care;
  final String? note;

  const Advice({
    required this.title,
    required this.symptoms,
    required this.treatment,
    required this.care,
    this.note,
  });

  factory Advice.fromMap(Map<String, dynamic> map) {
    final rawSymptoms = map['symptoms'];
    final rawTreatment = map['treatment'];
    final rawCare = map['care'];

    return Advice(
      title: (map['title'] ?? '').toString(),
      symptoms: rawSymptoms is List
          ? rawSymptoms.map((e) => e.toString()).toList()
          : const [],
      treatment: rawTreatment is List
          ? rawTreatment.map((e) => e.toString()).toList()
          : const [],
      care: rawCare is List
          ? rawCare.map((e) => e.toString()).toList()
          : const [],
      note: map['note']?.toString(),
    );
  }
}
