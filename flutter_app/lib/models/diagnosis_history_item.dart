import 'dart:convert';

class HistoryPrediction {
  final String label;
  final double confidence;

  const HistoryPrediction({
    required this.label,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
    };
  }

  factory HistoryPrediction.fromJson(Map<String, dynamic> json) {
    return HistoryPrediction(
      label: json['label'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DiagnosisHistoryItem {
  final String label;
  final String? title;
  final double confidence;
  final DateTime createdAt;

  final String? imagePath;
  final List<HistoryPrediction> predictions;
  final List<String> symptoms;
  final List<String> care;
  final String? note;

  const DiagnosisHistoryItem({
    required this.label,
    required this.confidence,
    required this.createdAt,
    this.title,
    this.imagePath,
    this.predictions = const [],
    this.symptoms = const [],
    this.care = const [],
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'title': title,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
      'imagePath': imagePath,
      'predictions': predictions.map((e) => e.toJson()).toList(),
      'symptoms': symptoms,
      'care': care,
      'note': note,
    };
  }

  factory DiagnosisHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawPredictions = json['predictions'];
    final rawSymptoms = json['symptoms'];
    final rawCare = json['care'];

    return DiagnosisHistoryItem(
      label: json['label'] as String? ?? '',
      title: json['title'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String?,
      predictions: rawPredictions is List
          ? rawPredictions
          .whereType<Map>()
          .map(
            (e) => HistoryPrediction.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList()
          : const [],
      symptoms: rawSymptoms is List
          ? rawSymptoms.map((e) => e.toString()).toList()
          : const [],
      care: rawCare is List
          ? rawCare.map((e) => e.toString()).toList()
          : const [],
      note: json['note'] as String?,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}