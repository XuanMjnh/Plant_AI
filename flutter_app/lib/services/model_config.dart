import 'dart:convert';
import 'package:flutter/services.dart';

class ModelConfig {
  final int inputWidth;
  final int inputHeight;
  final double mean;
  final double std;

// Số lượng kết quả hiển thị ra UI
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