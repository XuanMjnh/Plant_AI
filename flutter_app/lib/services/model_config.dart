import 'dart:convert';
import 'package:flutter/services.dart';

class ModelConfig {
  final int inputWidth;
  final int inputHeight;
  final double mean;
  final double std;
  final int topK;
  final String inputRange;
  final bool embeddedPreprocess;
  final bool cropToAspectRatio;
  final String inferenceHint;

  const ModelConfig({
    required this.inputWidth,
    required this.inputHeight,
    required this.mean,
    required this.std,
    required this.topK,
    required this.inputRange,
    required this.embeddedPreprocess,
    required this.cropToAspectRatio,
    required this.inferenceHint,
  });

  factory ModelConfig.defaults() {
    return const ModelConfig(
      inputWidth: 224,
      inputHeight: 224,
      mean: 0.0,
      std: 1.0,
      topK: 5,
      inputRange: '0_255_float',
      embeddedPreprocess: true,
      cropToAspectRatio: true,
      inferenceHint: 'resize_center_crop_then_rgb',
    );
  }

  ModelConfig copyWith({
    int? inputWidth,
    int? inputHeight,
    double? mean,
    double? std,
    int? topK,
    String? inputRange,
    bool? embeddedPreprocess,
    bool? cropToAspectRatio,
    String? inferenceHint,
  }) {
    return ModelConfig(
      inputWidth: inputWidth ?? this.inputWidth,
      inputHeight: inputHeight ?? this.inputHeight,
      mean: mean ?? this.mean,
      std: std ?? this.std,
      topK: topK ?? this.topK,
      inputRange: inputRange ?? this.inputRange,
      embeddedPreprocess: embeddedPreprocess ?? this.embeddedPreprocess,
      cropToAspectRatio: cropToAspectRatio ?? this.cropToAspectRatio,
      inferenceHint: inferenceHint ?? this.inferenceHint,
    );
  }

  static Future<ModelConfig> loadFromAssets(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return ModelConfig.fromJson(map);
  }

  static Future<ModelConfig> tryLoadFromAssets(String assetPath) async {
    try {
      return await loadFromAssets(assetPath);
    } catch (_) {
      return ModelConfig.defaults();
    }
  }

  factory ModelConfig.fromJson(Map<String, dynamic> map) {
    final preprocess = (map['preprocess'] as Map<String, dynamic>?) ?? const {};

    final imgSize = (map['img_size'] ?? map['inputSize'] ?? 224) as int;

    return ModelConfig(
      inputWidth: (map['inputWidth'] ?? imgSize) as int,
      inputHeight: (map['inputHeight'] ?? imgSize) as int,
      mean: (map['mean'] ?? 0.0).toDouble(),
      std: (map['std'] ?? 1.0).toDouble(),
      topK: (map['top_k'] ?? map['topK'] ?? 5) as int,
      inputRange:
      (preprocess['input_range'] ?? map['inputRange'] ?? '0_255_float')
          .toString(),
      embeddedPreprocess:
      (preprocess['embedded_in_model'] ?? map['embeddedPreprocess'] ?? true)
      as bool,
      cropToAspectRatio:
      (preprocess['crop_to_aspect_ratio'] ??
          map['cropToAspectRatio'] ??
          true) as bool,
      inferenceHint:
      (preprocess['inference_hint'] ??
          map['inferenceHint'] ??
          'resize_center_crop_then_rgb')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inputWidth': inputWidth,
      'inputHeight': inputHeight,
      'mean': mean,
      'std': std,
      'topK': topK,
      'inputRange': inputRange,
      'embeddedPreprocess': embeddedPreprocess,
      'cropToAspectRatio': cropToAspectRatio,
      'inferenceHint': inferenceHint,
    };
  }
}