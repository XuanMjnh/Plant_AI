import 'dart:convert';
import 'package:flutter/services.dart';

/// advice_repository.dart
/// ----------------------
/// Đọc file JSON mapping label -> tư vấn.
///
/// Format JSON (xem assets/data/advice_vi.json):
/// {
///   "Healthy": {
///     "title": "...",
///     "symptoms": ["..."],
///     "care": ["..."],
///     "note": "..."
///   },
///   "Tomato___Late_blight": { ... }
/// }
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

/// Model nhỏ cho phần tư vấn (để hiển thị UI)
class Advice {
  final String title;
  final List<String> symptoms;
  final List<String> care;
  final String? note;

  const Advice({
    required this.title,
    required this.symptoms,
    required this.care,
    this.note,
  });

  factory Advice.fromMap(Map<String, dynamic> map) {
    return Advice(
      title: (map['title'] ?? '').toString(),
      symptoms: (map['symptoms'] as List? ?? const []).map((e) => e.toString()).toList(),
      care: (map['care'] as List? ?? const []).map((e) => e.toString()).toList(),
      note: map['note']?.toString(),
    );
  }
}
