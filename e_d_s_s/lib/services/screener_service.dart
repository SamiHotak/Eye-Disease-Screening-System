import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction.dart';
import 'preprocessor.dart';

/// Everything about the exported model that the app must not guess.
/// Read from assets/model_info.json, which export_tflite.py writes, so
/// re-exporting at a different size or dtype needs no code change.
class ModelInfo {
  final int imgSize;
  final String inputDtype;
  final double inputScale;
  final int inputZeroPoint;
  final String outputDtype;
  final double outputScale;
  final int outputZeroPoint;

  const ModelInfo({
    required this.imgSize,
    required this.inputDtype,
    required this.inputScale,
    required this.inputZeroPoint,
    required this.outputDtype,
    required this.outputScale,
    required this.outputZeroPoint,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> j) => ModelInfo(
        imgSize: (j['img_size'] as num?)?.toInt() ?? 320,
        inputDtype: (j['input_dtype'] as String?) ?? 'uint8',
        inputScale: (j['input_scale'] as num?)?.toDouble() ?? 1.0,
        inputZeroPoint: (j['input_zero_point'] as num?)?.toInt() ?? 0,
        outputDtype: (j['output_dtype'] as String?) ?? 'uint8',
        outputScale: (j['output_scale'] as num?)?.toDouble() ?? 1.0,
        outputZeroPoint: (j['output_zero_point'] as num?)?.toInt() ?? 0,
      );

  bool get inputIsFloat => inputDtype.contains('float');
  bool get outputIsFloat => outputDtype.contains('float');
  bool get inputIsSigned => inputDtype.startsWith('int');
  bool get outputIsSigned => outputDtype.startsWith('int');
}

class ScreenerService {
  ScreenerService._();
  static final ScreenerService instance = ScreenerService._();

  Interpreter? _interpreter;
  List<String> _labels = const [];
  Map<String, double> _tuned = const {};
  ModelInfo? _info;
  String? _loadError;

  bool get isReady => _interpreter != null;
  String? get loadError => _loadError;
  List<String> get labels => _labels;
  ModelInfo get info => _info ?? const ModelInfo(
        imgSize: 320,
        inputDtype: 'uint8',
        inputScale: 1.0,
        inputZeroPoint: 0,
        outputDtype: 'uint8',
        outputScale: 1.0,
        outputZeroPoint: 0,
      );

  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      final infoRaw = await rootBundle.loadString('assets/model_info.json');
      _info = ModelInfo.fromJson(jsonDecode(infoRaw) as Map<String, dynamic>);

      final labelsRaw = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsRaw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      try {
        final thresholdsRaw =
            await rootBundle.loadString('assets/thresholds.json');
        final decoded = jsonDecode(thresholdsRaw) as Map<String, dynamic>;
        _tuned = decoded
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {
        _tuned = const {}; // optional asset: fall back to 0.5
      }

      final options = InterpreterOptions()..threads = 4;
      _interpreter =
          await Interpreter.fromAsset('assets/model.tflite', options: options);
      _interpreter!.allocateTensors();

      final outShape = _interpreter!.getOutputTensor(0).shape;
      final outCount = outShape.isEmpty ? 0 : outShape.last;
      if (outCount != _labels.length) {
        _loadError = 'Model outputs $outCount scores but labels.txt has '
            '${_labels.length} lines. They must match.';
        _interpreter?.close();
        _interpreter = null;
      } else {
        _loadError = null;
      }
    } catch (e) {
      _loadError = 'Could not load the model: $e';
      _interpreter = null;
    }
  }

  double thresholdFor(String label, ThresholdMode mode) => switch (mode) {
        ThresholdMode.sensitive => 0.30,
        ThresholdMode.specific => 0.50,
        ThresholdMode.balanced => _tuned[label] ?? 0.50,
      };

  Future<ScreenResult> analyze(Uint8List imageBytes, ThresholdMode mode) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError(_loadError ?? 'Model is not loaded yet.');
    }
    final meta = info;

    final preClock = Stopwatch()..start();
    final prepared = await compute(
      preprocessFundus,
      PreprocessRequest(imageBytes, meta.imgSize),
    );
    preClock.stop();

    final input = _buildInput(prepared.pixels, meta);
    final count = _labels.length;

    final inferClock = Stopwatch()..start();
    final List<double> probabilities;
    if (meta.outputIsFloat) {
      final output = [List<double>.filled(count, 0.0)];
      interpreter.run(input, output);
      probabilities = List<double>.from(output[0]);
    } else {
      final output = [List<int>.filled(count, 0)];
      interpreter.run(input, output);
      probabilities = output[0]
          .map((raw) => (raw - meta.outputZeroPoint) * meta.outputScale)
          .toList();
    }
    inferClock.stop();

    final predictions = <Prediction>[];
    for (int i = 0; i < count; i++) {
      final p = probabilities[i].clamp(0.0, 1.0).toDouble();
      predictions.add(Prediction(
        label: _labels[i],
        probability: p,
        threshold: thresholdFor(_labels[i], mode),
      ));
    }
    predictions.sort((a, b) => b.probability.compareTo(a.probability));

    return ScreenResult(
      all: predictions,
      preview: prepared.previewPng,
      inferenceMs: inferClock.elapsedMilliseconds,
      preprocessMs: preClock.elapsedMilliseconds,
    );
  }

  /// Shapes the pixels into [1, size, size, 3] in whatever dtype the exported
  /// model expects. With `--io uint8` the scale is 1.0 and zero point 0, so
  /// this is just the raw bytes.
  List<List<List<List<num>>>> _buildInput(Uint8List pixels, ModelInfo meta) {
    final size = meta.imgSize;
    final lo = meta.inputIsSigned ? -128 : 0;
    final hi = meta.inputIsSigned ? 127 : 255;

    return [
      List.generate(size, (y) {
        final row = y * size;
        return List.generate(size, (x) {
          final o = (row + x) * 3;
          if (meta.inputIsFloat) {
            return <num>[
              pixels[o].toDouble(),
              pixels[o + 1].toDouble(),
              pixels[o + 2].toDouble(),
            ];
          }
          return <num>[
            _quantize(pixels[o], meta, lo, hi),
            _quantize(pixels[o + 1], meta, lo, hi),
            _quantize(pixels[o + 2], meta, lo, hi),
          ];
        });
      })
    ];
  }

  int _quantize(int value, ModelInfo meta, int lo, int hi) {
    final q = (value / meta.inputScale + meta.inputZeroPoint).round();
    return q < lo ? lo : (q > hi ? hi : q);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
