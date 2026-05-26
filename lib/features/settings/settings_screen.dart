import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/export/bulk_markdown_exporter.dart';
import '../../data/models/ai_personality.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSyncOn = true;

  Future<void> _toggleHealth(bool on, AppSettings settings) async {
    final services = Services.of(context);
    final l = AppLocalizations.of(context);
    if (!on) {
      await settings.setHealthEnabled(false);
      return;
    }
    if (!services.health.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsHealthUnavailable)),
      );
      return;
    }
    final granted = await services.health.requestPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsHealthDenied)),
      );
      return;
    }
    await settings.setHealthEnabled(true);
  }

  Future<void> _confirmSignOut(BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsSignOutConfirm),
        content: Text(l.settingsSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.settingsSignOut),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final services = Services.of(context);
    final settings = AppSettingsScope.of(context);
    await services.auth.signOut();
    await settings.setCurrentUserId('');
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  Future<void> _bulkExport(AppLocalizations l) async {
    final services = Services.of(context);
    final entries = await services.diary.listEntries();
    if (!mounted) return;
    try {
      final count = await BulkMarkdownExporter.share(entries);
      if (!mounted) return;
      final msg = count == 0
          ? l.settingsBulkMarkdownNone
          : l.settingsBulkMarkdownDone(count);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export: $e')),
      );
    }
  }

  Future<void> _toggleCalendar(bool on, AppSettings settings) async {
    final services = Services.of(context);
    final l = AppLocalizations.of(context);
    if (!on) {
      await settings.setCalendarEnabled(false);
      return;
    }
    final granted = await services.calendar.requestPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsCalendarDenied)),
      );
      return;
    }
    await settings.setCalendarEnabled(true);
  }

  Future<void> _toggleTasks(bool on, AppSettings settings) async {
    final services = Services.of(context);
    final l = AppLocalizations.of(context);
    if (!on) {
      await settings.setTasksEnabled(false);
      return;
    }
    final granted = await services.tasks.requestPermissions();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsTasksDenied)),
      );
      return;
    }
    await settings.setTasksEnabled(true);
  }

  Future<void> _toggleLocation(bool on, AppSettings settings) async {
    final services = Services.of(context);
    final l = AppLocalizations.of(context);
    if (on) {
      final ok = await services.location.start();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.settingsLocationDenied)),
        );
        return;
      }
      await settings.setLocationEnabled(true);
    } else {
      await services.location.stop();
      await settings.setLocationEnabled(false);
    }
  }

  Future<void> _editApiKey(
    BuildContext context,
    AppSettings settings,
    AppLocalizations l,
  ) async {
    final controller = TextEditingController(text: settings.geminiApiKey);
    final result = await showDialog<_KeyDialogResult>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.settingsAiApiKeyDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              hintText: l.settingsAiApiKeyDialogHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, const _KeyDialogResult.clear()),
              child: Text(l.settingsAiApiKeyClear),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                ctx,
                _KeyDialogResult.save(controller.text),
              ),
              child: Text(l.commonSave),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    if (result.clear) {
      await settings.setGeminiApiKey('');
    } else {
      await settings.setGeminiApiKey(result.value ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          // 0. Account — surfaced at the top so users can sign out easily.
          if (settings.isSignedIn) ...[
            _SectionHeader(label: l.settingsAccount),
            _AccountTile(
              signedInAsLabel: l.settingsAccountSignedInAs,
              email: Services.of(context).auth.currentUser?.email
                  ?? l.settingsAccountDemo,
              signOutLabel: l.settingsSignOut,
              onSignOut: () => _confirmSignOut(context, l),
            ),
          ],
          // 1. Appearance
          _SectionHeader(label: l.settingsAppearance),
          _ListTile(
            label: l.settingsTheme,
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l.settingsThemeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l.settingsThemeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l.settingsThemeDark),
                ),
              ],
              onChanged: (v) {
                if (v != null) settings.setThemeMode(v);
              },
            ),
          ),
          _ListTile(
            label: l.settingsFontScale,
            trailing: DropdownButton<FontScale>(
              value: settings.fontScale,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: FontScale.small,
                  child: Text(l.fontScaleSmall),
                ),
                DropdownMenuItem(
                  value: FontScale.medium,
                  child: Text(l.fontScaleMedium),
                ),
                DropdownMenuItem(
                  value: FontScale.large,
                  child: Text(l.fontScaleLarge),
                ),
                DropdownMenuItem(
                  value: FontScale.extraLarge,
                  child: Text(l.fontScaleExtraLarge),
                ),
              ],
              onChanged: (v) {
                if (v != null) settings.setFontScale(v);
              },
            ),
          ),
          _ListTile(
            label: l.settingsAccent,
            trailing: SizedBox(
              width: 220,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in AppColors.accentChoices)
                    InkWell(
                      onTap: () => settings.setAccent(c),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: settings.accent == c
                                ? theme.colorScheme.onSurface
                                : theme.dividerColor,
                            width: settings.accent == c ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Daily goals (moved up — above personality)
          _SectionHeader(label: l.settingsGoals),
          _ListTile(
            label: l.goalsTitle,
            onTap: () => context.push(AppRoutes.goals),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),

          // 3. AI personality
          _SectionHeader(label: l.settingsAiPersonality),
          if (settings.isPremium)
            _PersonalityPicker(
              value: settings.personality,
              onChanged: settings.setPersonality,
            )
          else
            _LockedTile(
              icon: Icons.lock_outline,
              title: l.lockedPersonality,
              actionLabel: l.lockedPremium,
              onTap: () => context.push(AppRoutes.plan),
            ),

          // 4. Integrations
          _SectionHeader(label: l.settingsIntegrations),
          _SwitchTile(
            label: l.settingsHealth,
            value: settings.healthEnabled,
            onChanged: (v) => _toggleHealth(v, settings),
          ),
          _SwitchTile(
            label: l.settingsCalendar,
            value: settings.calendarEnabled,
            onChanged: (v) => _toggleCalendar(v, settings),
          ),
          _SwitchTile(
            label: l.settingsTodo,
            value: settings.tasksEnabled,
            onChanged: (v) => _toggleTasks(v, settings),
          ),
          _SwitchTile(
            label: l.settingsLocation,
            value: settings.locationEnabled,
            onChanged: (v) => _toggleLocation(v, settings),
          ),

          // 5. Plan
          _SectionHeader(label: l.settingsPlan),
          _ListTile(
            label: l.settingsUpgrade,
            onTap: () => context.push(AppRoutes.plan),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),

          // 6. Sync + export
          _SectionHeader(label: l.settingsAutoSync),
          _SwitchTile(
            label: l.settingsAutoSync,
            value: _autoSyncOn,
            onChanged: (v) => setState(() => _autoSyncOn = v),
          ),
          _DiaryFolderTile(
            label: l.settingsDiaryFolder,
            hint: l.settingsDiaryFolderHint,
            copyLabel: l.settingsDiaryFolderCopy,
            copiedLabel: l.settingsDiaryFolderCopied,
            path: Services.of(context).diary.folderPath,
          ),
          _ListTile(
            label: l.settingsBulkMarkdown,
            onTap: () => _bulkExport(l),
            trailing: const Icon(Icons.ios_share_outlined, size: 20),
            subtitle: l.settingsBulkMarkdownHint,
          ),
          _ListTile(
            label: l.settingsDataMigration,
            onTap: () {},
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),

          // 7. AI API (moved here — just above Referral)
          _SectionHeader(label: l.settingsAiApiTitle),
          if (settings.isPremium)
            _ApiKeyTile(
              label: l.settingsAiApiKey,
              masked: settings.geminiApiKeyMasked,
              placeholder: l.settingsAiApiKeyNotSet,
              help: l.settingsAiApiKeyHelp,
              onEdit: () => _editApiKey(context, settings, l),
            )
          else
            _LockedTile(
              icon: Icons.lock_outline,
              title: l.lockedByok,
              actionLabel: l.lockedPremium,
              onTap: () => context.push(AppRoutes.plan),
            ),

          // 8. Referral
          _SectionHeader(label: l.settingsReferral),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AID-7K3N9X',
                    style: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: 3,
                    )),
                const SizedBox(height: 8),
                Text(
                  l.settingsReferralBody,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // 9. Help / Language
          _ListTile(
            label: l.settingsHowTo,
            onTap: () => context.push(AppRoutes.tutorial),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _ListTile(
            label: l.settingsFaq,
            onTap: () => context.push(AppRoutes.faq),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _ListTile(
            label: l.settingsPrivacyPolicy,
            onTap: () => context.push(AppRoutes.privacy),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _ListTile(
            label: l.settingsTerms,
            onTap: () => context.push(AppRoutes.terms),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _ListTile(
            label: l.language,
            onTap: () async {
              final locale = await showDialog<Locale>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(l.language),
                  children: [
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(ctx, const Locale('ja')),
                      child: const Text('日本語'),
                    ),
                    SimpleDialogOption(
                      onPressed: () =>
                          Navigator.pop(ctx, const Locale('en')),
                      child: const Text('English'),
                    ),
                  ],
                ),
              );
              if (locale != null) await settings.setLocale(locale);
            },
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),

          const SizedBox(height: 24),
          Text(
            l.settingsPrivacyFooter,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2.2),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ListTile({
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String signedInAsLabel;
  final String email;
  final String signOutLabel;
  final VoidCallback onSignOut;
  const _AccountTile({
    required this.signedInAsLabel,
    required this.email,
    required this.signOutLabel,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signedInAsLabel,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSignOut,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(signOutLabel),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PersonalityPicker extends StatelessWidget {
  final AiPersonality value;
  final ValueChanged<AiPersonality> onChanged;

  const _PersonalityPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final items = [
      (
        AiPersonality.standard,
        l.personalityStandard,
        l.personalityStandardDesc,
      ),
      (
        AiPersonality.mirroring,
        l.personalityMirroring,
        l.personalityMirroringDesc,
      ),
      (
        AiPersonality.friendly,
        l.personalityFriendly,
        l.personalityFriendlyDesc,
      ),
    ];

    return Column(
      children: [
        for (final (p, title, desc) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(p),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(
                    color: p == value
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: p == value ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        p == value
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: p == value
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows the local diary folder path so users can configure their
/// Obsidian Vault to mirror this location.
class _DiaryFolderTile extends StatelessWidget {
  final String label;
  final String hint;
  final String copyLabel;
  final String copiedLabel;
  final String? path;

  const _DiaryFolderTile({
    required this.label,
    required this.hint,
    required this.copyLabel,
    required this.copiedLabel,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = path;
    if (p == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              color: theme.dividerColor.withValues(alpha: 0.35),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Courier',
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: copyLabel,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: p));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(copiedLabel)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyDialogResult {
  final String? value;
  final bool clear;
  const _KeyDialogResult.save(this.value) : clear = false;
  const _KeyDialogResult.clear()
      : value = null,
        clear = true;
}

class _LockedTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const _LockedTile({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyTile extends StatelessWidget {
  final String label;
  final String masked;
  final String placeholder;
  final String help;
  final VoidCallback onEdit;

  const _ApiKeyTile({
    required this.label,
    required this.masked,
    required this.placeholder,
    required this.help,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKey = masked.isNotEmpty;
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
                Text(
                  hasKey ? masked : placeholder,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasKey
                        ? theme.colorScheme.onSurface
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(help, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
