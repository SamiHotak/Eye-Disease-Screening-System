import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../data/condition_info.dart';
import '../services/screener_service.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ScreenerService.instance.labels;
    final visible = labels
        .where((l) => ConditionInfo.displayName(l)
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Text(AppInfo.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 3),
          Text('${AppInfo.fullName} · v${AppInfo.version}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),

          _Section(
            title: 'What it does',
            body: AppInfo.description,
          ),
          _Section(
            title: 'The model',
            body: AppInfo.modelSummary,
          ),
          _Section(
            title: 'Image preparation',
            body: AppInfo.preprocessingSummary,
          ),
          _Section(
            title: 'Training data',
            body: AppInfo.trainingData,
          ),

          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MEASURED PERFORMANCE',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 14),
                _Metric(label: 'Macro AUC', value: AppInfo.macroAuc),
                _Metric(
                    label: 'Mean average precision',
                    value: AppInfo.meanAveragePrecision),
                _Metric(label: 'Macro F1', value: AppInfo.macroF1),
                const SizedBox(height: 10),
                Text(
                  'Measured on held-out validation images, averaged across all '
                  'conditions. Rare conditions score well below these averages, '
                  'so a low-support finding deserves more scepticism than a '
                  'common one.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text('Detectable conditions (${labels.length})',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search conditions',
              hintStyle: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
              prefixIcon:
                  const Icon(Icons.search, size: 19, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accentDim),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (labels.isEmpty)
            Text('Labels load with the model. Open the screening page first.',
                style: theme.textTheme.bodySmall)
          else
            ...visible.map((l) => _ConditionTile(label: l)),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.danger.withAlpha(102)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.medical_information_outlined,
                        size: 18, color: AppTheme.danger),
                    SizedBox(width: 9),
                    Text('Not a medical device',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(AppInfo.disclaimerLong, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 7),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13.5, color: AppTheme.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent)),
        ],
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final String label;

  const _ConditionTile({required this.label});

  @override
  Widget build(BuildContext context) {
    final info = ConditionInfo.lookup(label);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.card,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: AppTheme.accent,
          collapsedIconColor: AppTheme.textSecondary,
          title: Text(info.display,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(info.summary,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
