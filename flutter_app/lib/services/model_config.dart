import 'dart:convert';
import 'package:flutter/services.dart';

class ModelConfig {
  final int inputWidth;
  final int inputHeight;

  /// Hiện tại model simple_cnn đã có Rescaling(1/255) bên trong model,
  /// nên Flutter không tự normalize bằng mean/std nữa.
  ///
  /// 2 trường này được giữ lại để sau này dễ đổi sang model khác.
  final double mean;
  final double std;

  /// Số lượng kết quả top-K hiển thị ra UI
  final int topK;

  const ModelConfig({
    required this.inputWidth,
    required this.inputHeight,
    required this.mean,
    required this.std,
    required this.topK,
  });

  factory ModelConfig.defaults() {
    return const ModelConfig(
      inputWidth: 224,
      inputHeight: 224,
      mean: 0.0,
      std: 1.0,
      topK: 3,
    );
  }

  static Future<ModelConfig> loadFromAssets(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return ModelConfig(
      inputWidth: (map['inputWidth'] ?? 224) as int,
      inputHeight: (map['inputHeight'] ?? 224) as int,
      mean: (map['mean'] ?? 0.0).toDouble(),
      std: (map['std'] ?? 1.0).toDouble(),
      topK: (map['topK'] ?? 3) as int,
    );
  }
}