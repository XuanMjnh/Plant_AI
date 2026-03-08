import 'dart:io';

import 'package:flutter/material.dart';

import '../data/advice_repository.dart';
import '../models/prediction.dart';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final List<Prediction> predictions;
  final Advice? advice;
  final String? topLabel;
  final String? errorMessage;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.predictions,
    required this.advice,
    required this.topLabel,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả nhận diện'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (errorMessage != null) _buildErrorCard(),
          if (errorMessage == null) ...[
            _buildPredictionCard(),
            const SizedBox(height: 12),
            _buildAdviceCard(),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại trang chủ'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          errorMessage!,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kết quả dự đoán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (predictions.isEmpty)
              const Text('Không có kết quả dự đoán.')
            else
              ...predictions.map(
                    (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.label,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Text(
                        '${(p.confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    if (advice == null || topLabel == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tư vấn: ${advice!.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Label model: $topLabel',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dấu hiệu thường gặp:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...advice!.symptoms.map((s) => Text('• $s')),
            const SizedBox(height: 12),
            const Text(
              'Gợi ý xử lý / chăm sóc:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...advice!.care.map((c) => Text('• $c')),
            if (advice!.note != null) ...[
              const SizedBox(height: 12),
              Text(
                'Lưu ý: ${advice!.note}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}