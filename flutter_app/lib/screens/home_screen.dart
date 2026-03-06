import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/advice_repository.dart';
import '../models/prediction.dart';
import '../services/classifier.dart';
import '../services/model_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _classifier = Classifier();

  AdviceRepository? _adviceRepo;

  File? _image;
  List<Prediction> _predictions = const [];
  bool _loading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _status = 'Đang tải model...';
    });

    // Load tư vấn
    _adviceRepo = await AdviceRepository.loadFromAssets('assets/data/advice_vi.json');

    // Load model + labels
    await _classifier.load(
      config: ModelConfig.defaults(),
    );

    setState(() {
      _status = _classifier.isLoaded
          ? '✅ Model đã sẵn sàng. Hãy chọn/chụp ảnh để nhận diện.'
          : '⚠️ Chưa có model.tflite (đang chạy chế độ mô phỏng). Hãy copy model vào assets/models/.';
    });
  }

  @override
  void dispose() {
    _classifier.close();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (xfile == null) return;
    await _runPredict(File(xfile.path));
  }

  Future<void> _takePhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 95);
    if (xfile == null) return;
    await _runPredict(File(xfile.path));
  }

  Future<void> _runPredict(File file) async {
    setState(() {
      _image = file;
      _loading = true;
      _predictions = const [];
      _status = 'Đang nhận diện...';
    });

    try {
      final preds = await _classifier.predict(file);
      setState(() {
        _predictions = preds;
        _status = 'Xong ✅';
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topLabel = _predictions.isNotEmpty ? _predictions.first.label : null;
    final advice = (topLabel != null && _adviceRepo != null) ? _adviceRepo!.getAdvice(topLabel) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Disease AI (TFLite)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildButtons(),
          const SizedBox(height: 12),
          _buildImagePreview(),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          _buildPredictions(),
          const SizedBox(height: 12),
          _buildAdvice(advice, topLabel),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _status ?? '',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _loading ? null : _takePhoto,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Chụp ảnh'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _loading ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Chọn ảnh'),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Chưa có ảnh. Hãy chụp hoặc chọn ảnh để bắt đầu.'),
          ),
        ),
      );
    }

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _image!,
          fit: BoxFit.cover,
          height: 260,
        ),
      ),
    );
  }

  Widget _buildPredictions() {
    if (_predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kết quả (Top-K)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._predictions.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(p.label)),
                    Text('${(p.confidence * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvice(Advice? advice, String? label) {
    if (advice == null || label == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tư vấn: ${advice.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Label: $label', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            const Text('Dấu hiệu thường gặp:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...advice.symptoms.map((s) => Text('• $s')),
            const SizedBox(height: 12),
            const Text('Gợi ý xử lý/chăm sóc:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...advice.care.map((c) => Text('• $c')),
            if (advice.note != null) ...[
              const SizedBox(height: 12),
              Text(
                'Lưu ý: ${advice.note}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
