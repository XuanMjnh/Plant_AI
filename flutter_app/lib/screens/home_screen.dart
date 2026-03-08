import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/advice_repository.dart';
import '../data/history_repository.dart';
import '../models/diagnosis_history_item.dart';
import '../services/classifier.dart';
import '../services/model_config.dart';
import 'history_detail_screen.dart';
import 'loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final Classifier _classifier = Classifier();

  AdviceRepository? _adviceRepo;

  bool _initializing = true;
  String? _initError;
  List<DiagnosisHistoryItem> _history = [];

  bool get _ready =>
      _classifier.isLoaded && _adviceRepo != null && !_initializing;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _initError = null;
    });

    try {
      _adviceRepo = await AdviceRepository.loadFromAssets(
        'assets/data/advice_vi.json',
      );

      await _classifier.load(
        config: ModelConfig.defaults(),
      );

      await _loadHistory();
    } catch (e) {
      _initError = 'Lỗi khởi tạo: $e';
    } finally {
      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    final items = await HistoryRepository.loadHistory();
    if (!mounted) return;

    setState(() {
      _history = items;
    });
  }

  Future<void> _clearHistory() async {
    await HistoryRepository.clearHistory();
    if (!mounted) return;

    setState(() {
      _history = [];
    });
  }

  Future<void> _deleteHistoryItem(int index) async {
    await HistoryRepository.deleteHistoryAt(index);
    if (!mounted) return;

    setState(() {
      _history.removeAt(index);
    });
  }

  void _openHistoryDetail(DiagnosisHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryDetailScreen(item: item),
      ),
    );
  }

  void _showDiseaseInfo({
    required String label,
    required Advice advice,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    advice.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Label: $label',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dấu hiệu thường gặp',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (advice.symptoms.isEmpty)
                    const Text('Chưa có dữ liệu.')
                  else
                    ...advice.symptoms.map(
                          (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $s'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gợi ý xử lý (nên làm ngay)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (advice.treatment.isEmpty)
                    const Text('Chưa có dữ liệu.')
                  else
                    ...advice.treatment.map(
                          (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $t'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gợi ý chăm sóc & phòng ngừa',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (advice.care.isEmpty)
                    const Text('Chưa có dữ liệu.')
                  else
                    ...advice.care.map(
                          (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $c'),
                      ),
                    ),
                  if (advice.note != null && advice.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Lưu ý',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      advice.note!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _classifier.close();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (!_ready) return;

    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (xfile == null) return;

    await _goToLoading(File(xfile.path));
  }

  Future<void> _takePhoto() async {
    if (!_ready) return;

    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (xfile == null) return;

    await _goToLoading(File(xfile.path));
  }

  Future<void> _goToLoading(File file) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoadingScreen(
          imageFile: file,
          classifier: _classifier,
          adviceRepo: _adviceRepo!,
          onHistoryChanged: () {
            _loadHistory();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = _classifier.labels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI chẩn đoán bệnh trên cây trồng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildButtons(),
          const SizedBox(height: 16),
          if (_initializing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!_initializing && _initError != null) ...[
            _buildInitErrorCard(),
            const SizedBox(height: 16),
          ],
          if (!_initializing && _ready) ...[
            _buildHistory(),
            const SizedBox(height: 16),
            _buildSupportedDiseases(labels),
          ],
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _ready ? _takePhoto : null,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Chụp ảnh'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _ready ? _pickFromGallery : null,
            icon: const Icon(Icons.photo_library),
            label: const Text('Chọn ảnh'),
          ),
        ),
      ],
    );
  }

  Widget _buildInitErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _initError ?? 'Không tải được model.',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSupportedDiseases(List<String> labels) {
    if (labels.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Không tìm thấy danh sách bệnh mà model hỗ trợ.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Các nhãn / bệnh model hỗ trợ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn vào từng bệnh để xem thông tin hỗ trợ.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.map((label) {
                final advice = _adviceRepo?.getAdvice(label);
                final displayText = advice?.title ?? label;

                return ActionChip(
                  avatar: const Icon(Icons.local_florist, size: 18),
                  label: Text(displayText),
                  onPressed: advice == null
                      ? null
                      : () {
                    _showDiseaseInfo(
                      label: label,
                      advice: advice,
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    const double historyListMaxHeight = 390;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lịch sử chẩn đoán',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_history.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearHistory,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa tất cả'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const Text('Chưa có lịch sử chẩn đoán.')
            else ...[
              if (_history.length > 3)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Vuốt xuống để xem thêm.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                  _history.length > 3 ? historyListMaxHeight : double.infinity,
                ),
                child: ListView.separated(
                  shrinkWrap: _history.length <= 3,
                  physics: _history.length > 3
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _history[index];

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openHistoryDetail(item),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.history),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title ?? item.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Label: ${item.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Độ tin cậy: ${(item.confidence * 100).toStringAsFixed(1)}%',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Thời gian: ${_formatDateTime(item.createdAt)}',
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Nhấn để xem chi tiết',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteHistoryItem(index),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Xóa lịch sử này',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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