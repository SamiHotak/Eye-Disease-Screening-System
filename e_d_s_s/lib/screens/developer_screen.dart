import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_info.dart';
import '../theme/app_theme.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('No app available to open ${uri.scheme}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = AppInfo.developerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Text('Developer', style: theme.textTheme.titleLarge),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.card,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.accent.withAlpha(115), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppInfo.developerPhoto,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      // falls back to initials if the photo is missing
                      errorBuilder: (context, error, stack) => Container(
                        width: 90,
                        height: 90,
                        color: AppTheme.accent.withAlpha(36),
                        alignment: Alignment.center,
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(AppInfo.developerName,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  '${AppInfo.developerRole} · ${AppInfo.developerInstitution}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _ContactTile(
            icon: Icons.mail_outline,
            label: 'Email',
            value: AppInfo.developerEmail,
            onTap: () => _open(
                context, Uri(scheme: 'mailto', path: AppInfo.developerEmail)),
          ),
          _ContactTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: AppInfo.developerPhone,
            onTap: () => _open(
                context, Uri(scheme: 'tel', path: AppInfo.developerPhone)),
          ),
          if (AppInfo.developerWebsite.isNotEmpty)
            _ContactTile(
              icon: Icons.language_outlined,
              label: 'Website',
              value: AppInfo.developerWebsite,
              onTap: () => _open(context, Uri.parse(AppInfo.developerWebsite)),
            ),
          if (AppInfo.supervisor.isNotEmpty)
            _ContactTile(
              icon: Icons.school_outlined,
              label: 'Supervisor',
              value: AppInfo.supervisor,
              onTap: null,
            ),

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ABOUT THIS PROJECT',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 11),
                Text(AppInfo.projectNote, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BUILT WITH',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                ...const [
                  'TensorFlow / Keras — EfficientNetV2-S training',
                  'TensorFlow Lite — int8 quantised on-device inference',
                  'Flutter & Dart — application layer',
                  'OpenCV — dataset preparation pipeline',
                ].map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 9),
                            child: SizedBox(
                              width: 5,
                              height: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('${AppInfo.name} v${AppInfo.version}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 19, color: AppTheme.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 3),
                      Text(value,
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.open_in_new,
                      size: 16, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
