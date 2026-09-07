import 'dart:typed_data';

import '../data/condition_info.dart';

/// How aggressively a finding gets flagged.
enum ThresholdMode {
  /// 0.30 everywhere: catches more, cries wolf more. Screening posture.
  sensitive,

  /// The per-class values in thresholds.json, tuned for best F1 on validation.
  balanced,

  /// 0.50 everywhere: flags only confident findings.
  specific,
}

extension ThresholdModeLabel on ThresholdMode {
  String get label => switch (this) {
        ThresholdMode.sensitive => 'Sensitive',
        ThresholdMode.balanced => 'Balanced',
        ThresholdMode.specific => 'Specific',
      };

  String get explanation => switch (this) {
        ThresholdMode.sensitive =>
          'Flags anything above 0.30. Fewer missed findings, more false alarms.',
        ThresholdMode.balanced =>
          'Uses the per-condition cut-offs tuned during training. Recommended.',
        ThresholdMode.specific =>
          'Flags only above 0.50. Fewer false alarms, more missed findings.',
      };
}

class Prediction {
  final String label;
  final double probability;
  final double threshold;

  const Prediction({
    required this.label,
    required this.probability,
    required this.threshold,
  });

  bool get flagged => probability >= threshold;

  String get display => ConditionInfo.displayName(label);

  ConditionInfo get info => ConditionInfo.lookup(label);

  bool get isNormal => label.toLowerCase().replaceAll('_', '') == 'normal';
}

class ScreenResult {
  /// Every label, sorted by probability descending.
  final List<Prediction> all;

  /// PNG of the exact image the model analysed.
  final Uint8List preview;
  final int inferenceMs;
  final int preprocessMs;

  const ScreenResult({
    required this.all,
    required this.preview,
    required this.inferenceMs,
    required this.preprocessMs,
  });

  List<Prediction> get flagged => all.where((p) => p.flagged).toList();

  /// True when nothing crossed its threshold, or the only flag is "Normal".
  bool get isClear {
    final hits = flagged.where((p) => !p.isNormal).toList();
    return hits.isEmpty;
  }
}
