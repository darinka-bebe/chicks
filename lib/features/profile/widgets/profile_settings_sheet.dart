import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProfileSettingsSheet extends StatelessWidget {
  const ProfileSettingsSheet({
    super.key,
    required this.onResetDemo,
    required this.onResetAll,
  });

  final VoidCallback onResetDemo;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.settingsTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppBrandColors.title,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppBrandColors.iconBackground.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        loc.settingsAbout,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.settingsDemoSection,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.pink,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.school_outlined,
                      title: loc.settingsRepeatTutorial,
                      subtitle: loc.settingsRepeatTutorialSub,
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed(
                          RouteNames.tutorialName,
                          queryParameters: {'from': 'profile'},
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.restart_alt_rounded,
                      title: loc.settingsResetDemo,
                      subtitle: loc.settingsResetDemoSub,
                      onTap: () {
                        Navigator.pop(context);
                        onResetDemo();
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      title: loc.settingsResetAll,
                      subtitle: loc.settingsResetAllSub,
                      destructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        onResetAll();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : AppBrandColors.pink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: destructive
                                ? Colors.redAccent
                                : AppBrandColors.title,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
