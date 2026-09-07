import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../theme/app_theme.dart';

class ConfidenceRow extends StatefulWidget {
  final Prediction prediction;
  final bool expandable;

  const ConfidenceRow({
    super.key,
    required this.prediction,
    this.expandable = true,
  });

  @override
  State<ConfidenceRow> createState() => _ConfidenceRowState();
}

class _ConfidenceRowState extends State<ConfidenceRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final color = p.flagged ? AppTheme.forConfidence(p.probability) : AppTheme.textSecondary;
    final percent = (p.probability * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.expandable ? () => setState(() => _open = !_open) : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.display,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: p.flagged ? FontWeight.w600 : FontWeight.w500,
                            color: p.flagged
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (widget.expandable)
                        Icon(
                          _open ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _Bar(value: p.probability, threshold: p.threshold, color: color),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.info.summary,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Flag threshold ${p.threshold.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.4,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final double threshold;
  final Color color;

  const _Bar({required this.value, required this.threshold, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              // threshold tick
              Positioned(
                left: (width * threshold.clamp(0.0, 1.0)) - 1,
                child: Container(
                  width: 2,
                  height: 8,
                  color: AppTheme.textSecondary.withAlpha(140),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
