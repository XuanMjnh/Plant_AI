import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction.dart';
import 'model_config.dart';

class Classifier {
  Interpreter? _interpreter;
  late List<String> _labels;
  late ModelConfig _config;

  bool get isLoaded => _interpreter != null;

  Future<void> load({
    String modelAssetPath = 'assets/models/model.tflite',
    String labelsAssetPath = 'assets/models/labels.txt',
    ModelConfig? config,
  }) async {
    _config = config ?? ModelConfig.defaults();

    final labelsRaw = await rootBundle.loadString(labelsAssetPath);
    _labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      final shape = inputTensor.shape; // [1, H, W, 3]
      if (shape.length == 4) {
        _config = ModelConfig(
          inputWidth: shape[2],
          inputHeight: shape[1],
          mean: _config.mean,
          std: _config.std,
          topK: _config.topK,
        );
      }

      print('INPUT shape: ${inputTensor.shape}');
      print('INPUT type : ${inputTensor.type}');
      print('OUTPUT shape: ${outputTensor.shape}');
      print('OUTPUT type : ${outputTensor.type}');
      print('LABELS count: ${_labels.length}');
    } catch (e) {
      _interpreter = null;
    }
  }

  Future<List<Prediction>> predict(File imageFile) async {
    if (_interpreter == null) {
      return _mockPredict();
    }

    final input = _preprocess(imageFile);
    final output = _createOutputBuffer(_labels.length);

    _interpreter!.run(input, output);

    print('RAW OUTPUT: ${output[0]}');

    final probs = (output[0] as List).cast<double>();
    return _topK(probs, _config.topK);
  }

  /// Model Python đã có Rescaling(1/255) bên trong,
  /// nên ở Flutter giữ pixel dạng 0..255.
  List<List<List<List<double>>>> _preprocess(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Không decode được ảnh.');
    }

    final resized = img.copyResize(
      decoded,
      width: _config.inputWidth,
      height: _config.inputHeight,
      interpolation: img.Interpolation.average,
    );

    final input = List.generate(
      1,
          (_) => List.generate(
        _config.inputHeight,
            (y) => List.generate(
          _config.inputWidth,
              (x) {
            final pixel = resized.getPixel(x, y);
            return <double>[
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    return input;
  }

  List<List<double>> _createOutputBuffer(int numClasses) {
    return List.generate(1, (_) => List.filled(numClasses, 0.0));
  }

  List<Prediction> _topK(List<double> probs, int k) {
    final indexed = <int, double>{};
    for (var i = 0; i < probs.length; i++) {
      indexed[i] = probs[i];
    }

    final sorted = indexed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(min(k, sorted.length)).toList();
    return top
        .map(
          (e) => Prediction(
        label: e.key < _labels.length ? _labels[e.key] : 'Class_${e.key}',
        confidence: e.value,
      ),
    )
        .toList();
  }

  List<Prediction> _mockPredict() {
    final rng = Random();
    final n = min(_labels.length, 3);
    final picks = <Prediction>[];

    final indices = List.generate(_labels.length, (i) => i)..shuffle();
    for (var i = 0; i < n; i++) {
      picks.add(
        Prediction(
          label: _labels[indices[i]],
          confidence: 0.5 + rng.nextDouble() * 0.5,
        ),
      );
    }

    picks.sort((a, b) => b.confidence.compareTo(a.confidence));
    return picks;
  }

  void close() {
    _interpreter?.close();
  }
}