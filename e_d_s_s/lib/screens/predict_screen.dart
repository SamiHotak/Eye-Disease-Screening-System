import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_info.dart';
import '../models/prediction.dart';
import '../services/screener_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_row.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _picker = ImagePicker();
  final _service = ScreenerService.instance;

  bool _loadingModel = true;
  bool _busy = false;
  String? _error;
  Uint8List? _sourceBytes;
  ScreenResult? _result;
  ThresholdMode _mode = ThresholdMode.balanced;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    await _service.load();
    if (!mounted) return;
    setState(() {
      _loadingModel = false;
      _error = _service.loadError;
    });
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy || !_service.isReady) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 95,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _sourceBytes = bytes;
        _result = null;
        _error = null;
        _busy = true;
        _showAll = false;
      });
      await _run();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not open that image: $e';
      });
    }
  }

  Future<void> _run() async {
    final bytes = _sourceBytes;
    if (bytes == null) return;
    try {
      final result = await _service.analyze(bytes, _mode);
      if (!mounted) return;
      setState(() {
        _result = result;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Analysis failed: $e';
      });
    }
  }

  Future<void> _changeMode(ThresholdMode mode) async {
    setState(() => _mode = mode);
    if (_sourceBytes == null) return;
    setState(() => _busy = true);
    await _run();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _header(theme),
          const SizedBox(height: 20),
          if (_loadingModel) _statusCard('Loading model…', spinner: true),
          if (!_loadingModel && _error != null) _errorCard(_error!),
          if (!_loadingModel && _service.isReady) ...[
            _imagePanel(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.image_outlined, size: 20),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _modeSelector(),
            if (_result != null) ...[
              const SizedBox(height: 22),
              _resultsSection(theme, _result!),
            ],
          ],
          const SizedBox(height: 26),
          _disclaimer(),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppInfo.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(AppInfo.tagline, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withAlpha(31),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withAlpha(89)),
          ),
          child: const Text(
            'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePanel() {
    final preview = _result?.preview;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (preview != null)
              Image.memory(preview, fit: BoxFit.cover, gaplessPlayback: true)
            else if (_sourceBytes != null)
              Image.memory(_sourceBytes!, fit: BoxFit.cover)
            else
              const _EmptyPanel(),
            if (_busy)
              Container(
                color: AppTheme.background.withAlpha(184),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                      SizedBox(height: 14),
                      Text('Analysing fundus…',
                          style: TextStyle(
                              fontSize: 12.5, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            if (preview != null && !_busy)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withAlpha(191),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AS ANALYSED',
                    style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FLAG THRESHOLD',
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThresholdMode>(
            segments: ThresholdMode.values
                .map((m) => ButtonSegment<ThresholdMode>(
                      value: m,
                      label: Text(m.label, style: const TextStyle(fontSize: 12.5)),
                    ))
                .toList(),
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: _busy
                ? null
                : (set) => _changeMode(set.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? AppTheme.accent.withAlpha(41)
                      : AppTheme.surface),
              side: WidgetStateProperty.all(
                  const BorderSide(color: AppTheme.border)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(_mode.explanation,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _resultsSection(ThemeData theme, ScreenResult result) {
    final flagged = result.flagged.where((p) => !p.isNormal).toList();
    final rest = result.all
        .where((p) => !flagged.contains(p))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              result.isClear ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              size: 19,
              color: result.isClear ? AppTheme.accent : AppTheme.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.isClear
                    ? 'No finding crossed its threshold'
                    : '${flagged.length} finding${flagged.length == 1 ? '' : 's'} above threshold',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'prep ${result.preprocessMs} ms · inference ${result.inferenceMs} ms',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        if (flagged.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.card,
            child: Text(
              'Nothing scored above the current threshold. That is not a clean '
              'bill of health: early disease can score low, and image quality '
              'affects every score.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          ...flagged.map((p) => ConfidenceRow(prediction: p)),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => setState(() => _showAll = !_showAll),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accent,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(_showAll
              ? 'Hide remaining scores'
              : 'Show all ${result.all.length} scores'),
        ),
        if (_showAll) ...[
          const SizedBox(height: 8),
          ...rest.map((p) => ConfidenceRow(prediction: p)),
        ],
      ],
    );
  }

  Widget _statusCard(String message, {bool spinner = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card,
      child: Row(
        children: [
          if (spinner)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (spinner) const SizedBox(width: 14),
          Expanded(
              child: Text(message,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withAlpha(115)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, height: 1.45, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withAlpha(89)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppTheme.warning),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              AppInfo.disclaimerShort,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.45, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border, width: 2),
          ),
          child: const Icon(Icons.remove_red_eye_outlined,
              size: 32, color: AppTheme.accentDim),
        ),
        const SizedBox(height: 14),
        const Text('No image yet',
            style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 34),
          child: Text(
            'Use a retinal fundus photograph, not a photo of the outside of an eye.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, height: 1.4, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
