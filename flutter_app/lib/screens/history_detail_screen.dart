import 'dart:io';

import 'package:flutter/material.dart';

import '../models/diagnosis_history_item.dart';

class HistoryDetailScreen extends StatelessWidget {
  final DiagnosisHistoryItem item;

  const HistoryDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final imageFile = item.imagePath != null ? File(item.imagePath!) : null;
    final imageExists = imageFile != null && imageFile.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chẩn đoán'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageExists
                  ? Image.file(
                imageFile,
                height: 260,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 260,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, size: 48),
                    SizedBox(height: 8),
                    Text('Không tìm thấy ảnh của lần chẩn đoán này'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPredictionCard(),
          const SizedBox(height: 12),
          _buildAdviceCard(),
          const SizedBox(height: 12),
          _buildTimeCard(),
        ],
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
            if (item.predictions.isEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title ?? item.label,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Text(
                    '${(item.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            else
              ...item.predictions.map(
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tư vấn: ${item.title ?? item.label}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Label model: ${item.label}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dấu hiệu thường gặp:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (item.symptoms.isEmpty)
              const Text('Chưa có dữ liệu dấu hiệu.')
            else
              ...item.symptoms.map((s) => Text('• $s')),
            const SizedBox(height: 12),
            const Text(
              'Gợi ý xử lý / chăm sóc:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (item.care.isEmpty)
              const Text('Chưa có dữ liệu chăm sóc.')
            else
              ...item.care.map((c) => Text('• $c')),
            if (item.note != null && item.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Lưu ý: ${item.note}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Thời gian: ${_formatDateTime(item.createdAt)}'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final day = twoDigits(dt.day);
    final month = twoDigits(dt.month);
    final year = dt.year.toString();
    final hour = twoDigits(dt.hour);
    final minute = twoDigits(dt.minute);

    return '$day/$month/$year - $hour:$minute';
  }
}