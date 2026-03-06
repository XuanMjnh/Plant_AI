/// prediction.dart
/// --------------
/// Kết quả dự đoán 1 lớp (label) + độ tin cậy (confidence).
class Prediction {
  final String label;
  final double confidence;

  const Prediction({
    required this.label,
    required this.confidence,
  });
}
