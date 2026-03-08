import 'dart:io';

import 'package:flutter/material.dart';

import '../data/advice_repository.dart';
import '../data/history_repository.dart';
import '../models/diagnosis_history_item.dart';
import '../models/prediction.dart';
import '../services/classifier.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final File imageFile;
  final Classifier classifier;
  final AdviceRepository adviceRepo;
  final VoidCallback? onHistoryChanged;

  const LoadingScreen({
    super.key,
    required this.imageFile,
    required this.classifier,
    required this.adviceRepo,
    this.onHistoryChanged,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  static const Duration _minLoadingDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _runPrediction();
  }

  Future<void> _runPrediction() async {
    try {
      final predictionFuture = widget.classifier.predict(widget.imageFile);
      final delayFuture = Future.delayed(_minLoadingDuration);

      final List<Prediction> predictions = await predictionFuture;

      final topLabel = predictions.isNotEmpty ? predictions.first.label : null;
      final advice =
      topLabel != null ? widget.adviceRepo.getAdvice(topLabel) : null;

      if (predictions.isNotEmpty && topLabel != null) {
        await HistoryRepository.addHistory(
          DiagnosisHistoryItem(
            label: topLabel,
            title: advice?.title ?? topLabel,
            confidence: predictions.first.confidence,
            createdAt: DateTime.now(),
            imagePath: widget.imageFile.path,
            predictions: predictions
                .map(
                  (p) => HistoryPrediction(
                label: p.label,
                confidence: p.confidence,
              ),
            )
                .toList(),
            symptoms: advice?.symptoms ?? const [],
            care: advice?.care ?? const [],
            note: advice?.note,
          ),
        );

        widget.onHistoryChanged?.call();
      }

      await delayFuture;

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: widget.imageFile,
            predictions: predictions,
            advice: advice,
            topLabel: topLabel,
          ),
        ),
      );
    } catch (e) {
      await Future.delayed(_minLoadingDuration);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: widget.imageFile,
            predictions: const [],
            advice: null,
            topLabel: null,
            errorMessage: 'Lỗi khi nhận diện: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đang kiểm tra'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
              SizedBox(height: 24),
              Icon(Icons.spa, size: 56),
              SizedBox(height: 16),
              Text(
                'Hệ thống đang phân tích ảnh cây trồng...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Vui lòng chờ trong giây lát',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}