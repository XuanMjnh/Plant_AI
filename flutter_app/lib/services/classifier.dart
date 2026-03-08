import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction.dart';
import 'model_config.dart';

class Classifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  late ModelConfig _config;
  Tensor? _inputTensor;
  Tensor? _outputTensor;

  bool get isLoaded => _interpreter != null;
  List<String> get labels => List.unmodifiable(_labels);
  ModelConfig get config => _config;

  Future<void> load({
    String modelAssetPath = 'assets/models/model.tflite',
    String labelsAssetPath = 'assets/models/labels.txt',
    String metadataAssetPath = 'assets/models/model_meta.json',
    ModelConfig? config,
  }) async {
    _config = config ?? await ModelConfig.tryLoadFromAssets(metadataAssetPath);

    final labelsRaw = await rootBundle.loadString(labelsAssetPath);
    _labels = labelsRaw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);

      _inputTensor = _interpreter!.getInputTensor(0);
      _outputTensor = _interpreter!.getOutputTensor(0);

      final inputShape = _inputTensor!.shape; // [1, H, W, 3]
      if (inputShape.length == 4) {
        _config = _config.copyWith(
          inputWidth: inputShape[2],
          inputHeight: inputShape[1],
        );
      }

      final outputShape = _outputTensor!.shape;
      final numClasses = outputShape.isNotEmpty ? outputShape.last : _labels.length;
      if (_labels.length != numClasses) {
        print(
          'Cảnh báo: labels=${_labels.length} nhưng output classes=$numClasses. '
          'Sẽ dùng output của model làm chuẩn.',
        );
      }

      print('INPUT shape : ${_inputTensor!.shape}');
      print('INPUT type  : ${_inputTensor!.type}');
      print('INPUT q     : scale=${_safeScale(_inputTensor!)} zp=${_safeZeroPoint(_inputTensor!)}');
      print('OUTPUT shape: ${_outputTensor!.shape}');
      print('OUTPUT type : ${_outputTensor!.type}');
      print('OUTPUT q    : scale=${_safeScale(_outputTensor!)} zp=${_safeZeroPoint(_outputTensor!)}');
      print('LABELS count: ${_labels.length}');
      print('CONFIG      : ${_config.toJson()}');
    } catch (e) {
      print('Không load được model: $e');
      _interpreter = null;
      _inputTensor = null;
      _outputTensor = null;
      rethrow;
    }
  }

  Future<List<Prediction>> predict(File imageFile) async {
    if (_labels.isEmpty) {
      throw Exception('Chưa load labels.');
    }
    if (_interpreter == null || _inputTensor == null || _outputTensor == null) {
      throw Exception('Model chưa được load.');
    }

    final input = _createInputBuffer(imageFile);
    final output = _createOutputBuffer();

    _interpreter!.run(input, output);

    final probs = _extractOutputScores(output);
    return _topK(probs, _config.topK);
  }

  Object _createInputBuffer(File imageFile) {
    final image = _decodeAndPrepareImage(imageFile);
    final inputType = _inputTensor!.type.toString();

    if (inputType.contains('float32')) {
      return List.generate(
        1,
        (_) => List.generate(
          _config.inputHeight,
          (y) => List.generate(
            _config.inputWidth,
            (x) {
              final pixel = image.getPixel(x, y);
              return <double>[
                _normalizeFloat(pixel.r.toDouble()),
                _normalizeFloat(pixel.g.toDouble()),
                _normalizeFloat(pixel.b.toDouble()),
              ];
            },
          ),
        ),
      );
    }

    if (inputType.contains('uint8') || inputType.contains('int8')) {
      return List.generate(
        1,
        (_) => List.generate(
          _config.inputHeight,
          (y) => List.generate(
            _config.inputWidth,
            (x) {
              final pixel = image.getPixel(x, y);
              return <int>[
                _quantizeInputValue(pixel.r.toDouble()),
                _quantizeInputValue(pixel.g.toDouble()),
                _quantizeInputValue(pixel.b.toDouble()),
              ];
            },
          ),
        ),
      );
    }

    throw UnsupportedError('Kiểu input tensor chưa hỗ trợ: ${_inputTensor!.type}');
  }

  img.Image _decodeAndPrepareImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Không decode được ảnh.');
    }

    final prepared = _config.cropToAspectRatio
        ? _centerCropToAspect(decoded, _config.inputWidth, _config.inputHeight)
        : decoded;

    return img.copyResize(
      prepared,
      width: _config.inputWidth,
      height: _config.inputHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _centerCropToAspect(img.Image src, int targetW, int targetH) {
    final srcW = src.width;
    final srcH = src.height;
    final srcAspect = srcW / srcH;
    final targetAspect = targetW / targetH;

    int cropW = srcW;
    int cropH = srcH;
    int offsetX = 0;
    int offsetY = 0;

    if (srcAspect > targetAspect) {
      cropW = max(1, (srcH * targetAspect).round());
      offsetX = ((srcW - cropW) / 2).round();
    } else if (srcAspect < targetAspect) {
      cropH = max(1, (srcW / targetAspect).round());
      offsetY = ((srcH - cropH) / 2).round();
    }

    return img.copyCrop(
      src,
      x: offsetX,
      y: offsetY,
      width: cropW,
      height: cropH,
    );
  }

  double _normalizeFloat(double pixel) {
    switch (_config.inputRange) {
      case 'normalized_0_1':
        return pixel / 255.0;
      case 'minus1_to_1':
        return (pixel / 127.5) - 1.0;
      case '0_255_float':
      default:
        return (pixel - _config.mean) / _config.std;
    }
  }

  int _quantizeInputValue(double pixel) {
    final normalized = _normalizeFloat(pixel);
    final scale = _safeScale(_inputTensor!);
    final zeroPoint = _safeZeroPoint(_inputTensor!);

    if (scale == 0) {
      return normalized.round();
    }

    final raw = (normalized / scale) + zeroPoint;
    final inputType = _inputTensor!.type.toString();

    if (inputType.contains('uint8')) {
      return raw.round().clamp(0, 255).toInt();
    }

    if (inputType.contains('int8')) {
      return raw.round().clamp(-128, 127).toInt();
    }

    return raw.round();
  }

  Object _createOutputBuffer() {
    final outputShape = _outputTensor!.shape;
    final batch = outputShape.isNotEmpty ? outputShape.first : 1;
    final numClasses = outputShape.isNotEmpty ? outputShape.last : _labels.length;
    final outputType = _outputTensor!.type.toString();

    if (outputType.contains('float32')) {
      return List.generate(batch, (_) => List<double>.filled(numClasses, 0.0));
    }

    if (outputType.contains('uint8') || outputType.contains('int8')) {
      return List.generate(batch, (_) => List<int>.filled(numClasses, 0));
    }

    throw UnsupportedError('Kiểu output tensor chưa hỗ trợ: ${_outputTensor!.type}');
  }

  List<double> _extractOutputScores(Object output) {
    if (output is! List || output.isEmpty || output.first is! List) {
      throw StateError('Không đọc được output từ model. Kiểu thực tế: ${output.runtimeType}');
    }

    final firstRow = List<dynamic>.from(output.first as List);
    if (firstRow.isEmpty) {
      return <double>[];
    }

    if (firstRow.first is int) {
      final values = firstRow.map((e) => e as int).toList();
      final scale = _safeScale(_outputTensor!);
      final zeroPoint = _safeZeroPoint(_outputTensor!);
      if (scale == 0) {
        return values.map((e) => e.toDouble()).toList();
      }
      return values.map((e) => (e - zeroPoint) * scale).toList();
    }

    return firstRow.map((e) => (e as num).toDouble()).toList();
  }

  double _safeScale(Tensor tensor) {
    try {
      return tensor.params.scale;
    } catch (_) {
      return 0.0;
    }
  }

  int _safeZeroPoint(Tensor tensor) {
    try {
      return tensor.params.zeroPoint;
    } catch (_) {
      return 0;
    }
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

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _inputTensor = null;
    _outputTensor = null;
  }
}
