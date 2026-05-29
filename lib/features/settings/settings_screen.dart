import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/notifications/diary_reminder_service.dart';
import '../../core/notifications/radio_notification_service.dart';
import '../../data/models/ai_personality.dart';
import '../../data/models/radio_voice_personality.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

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

  /// Enables/disables the daily diary-reminder notification.
  /// Requests permission on first enable (Android 13+).
  Future<void> _toggleDiaryReminder(bool on, AppSettings settings) async {
    if (!on) {
      await settings.setDiaryReminderEnabled(false);
      await DiaryReminderService.instance.cancel();
      return;
    }
    final granted = await DiaryReminderService.instance.requestPermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('通知の許可が必要です。端末の設定アプリから「AI Diary」の通知を許可してください。'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    await settings.setDiaryReminderEnabled(true);
    await DiaryReminderService.instance.scheduleDaily(
      hour: settings.diaryReminderHour,
      enabled: true,
    );
  }

  /// Enables/disables AIラジオ weekly & monthly notifications.
  Future<void> _toggleRadioNotifications(bool on, AppSettings settings) async {
    await settings.setRadioNotificationsEnabled(on);
    await RadioNotificationService.instance.scheduleAll(enabled: on);
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

          // 3b. AIラジオ声質
          _SectionHeader(label: 'AIラジオ 声'),
          // Gender (free)
          _RadioGenderPicker(
            value: settings.radioVoiceGender,
            onChanged: settings.setRadioVoiceGender,
          ),
          const SizedBox(height: 8),
          // Voice type (premium for non-standard)
          if (settings.isPremium)
            _RadioVoicePicker(
              value: settings.radioVoiceType,
              onChanged: settings.setRadioVoiceType,
            )
          else ...[
            // Show standard as selected + locked others
            _RadioVoicePicker(
              value: RadioVoiceType.standard,
              onChanged: settings.setRadioVoiceType,
              lockedTypes: const {
                RadioVoiceType.healing,
                RadioVoiceType.energetic,
                RadioVoiceType.dj,
              },
              onLockedTap: () => context.push(AppRoutes.plan),
            ),
          ],

          // 4. Notifications
          _SectionHeader(label: '通知'),
          _SwitchTile(
            label: '毎日の日記リマインダー',
            subtitle: '毎晩${settings.diaryReminderHour}時に通知します',
            value: settings.diaryReminderEnabled,
            onChanged: (v) => _toggleDiaryReminder(v, settings),
          ),
          // Time picker row — visible only when reminder is enabled.
          if (settings.diaryReminderEnabled)
            _NotifTimeTile(
              hour: settings.diaryReminderHour,
              onChanged: (hour) async {
                await settings.setDiaryReminderHour(hour);
                await DiaryReminderService.instance.scheduleDaily(
                  hour: hour,
                  enabled: true,
                );
              },
            ),
          _SwitchTile(
            label: 'AIラジオ通知',
            subtitle: '毎週日曜・月末に生成をお知らせします',
            value: settings.radioNotificationsEnabled,
            onChanged: (v) => _toggleRadioNotifications(v, settings),
          ),

          // 5. Integrations
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

          // 6. カスタム設定（上級者向け）
          _SectionHeader(label: 'カスタム'),
          _ListTile(
            label: 'カスタム設定',
            subtitle: 'AI API・Obsidian連携・データ管理',
            onTap: () => context.push(AppRoutes.customSettings),
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),

          // 7. Referral
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

          // Account / Sign out — at the very bottom
          if (settings.isSignedIn) ...[
            const SizedBox(height: 8),
            _SectionHeader(label: l.settingsAccount),
            _AccountTile(
              signedInAsLabel: l.settingsAccountSignedInAs,
              email: Services.of(context).auth.currentUser?.email
                  ?? l.settingsAccountDemo,
              signOutLabel: l.settingsSignOut,
              onSignOut: () => _confirmSignOut(context, l),
            ),
          ],

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
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.label,
    this.subtitle,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Radio voice pickers
// ─────────────────────────────────────────────────────────────────────────────

class _RadioGenderPicker extends StatelessWidget {
  final RadioVoiceGender value;
  final void Function(RadioVoiceGender) onChanged;

  const _RadioGenderPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('声の性別', style: theme.textTheme.bodyLarge),
          const Spacer(),
          _GenderChip(
            label: '女性',
            selected: value == RadioVoiceGender.female,
            onTap: () => onChanged(RadioVoiceGender.female),
          ),
          const SizedBox(width: 8),
          _GenderChip(
            label: '男性',
            selected: value == RadioVoiceGender.male,
            onTap: () => onChanged(RadioVoiceGender.male),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RadioVoicePicker extends StatelessWidget {
  final RadioVoiceType value;
  final void Function(RadioVoiceType) onChanged;
  final Set<RadioVoiceType> lockedTypes;
  final VoidCallback? onLockedTap;

  const _RadioVoicePicker({
    required this.value,
    required this.onChanged,
    this.lockedTypes = const {},
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: RadioVoiceType.values.map((type) {
        final isLocked = lockedTypes.contains(type);
        final isSelected = value == type;
        return GestureDetector(
          onTap: isLocked ? onLockedTap : () => onChanged(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // Radio circle
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.labelJa,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isLocked
                              ? theme.textTheme.bodySmall?.color
                              : null,
                        ),
                      ),
                      Text(
                        type.descJa,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: isLocked ? 0.5 : 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Premium',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Notification time picker row ─────────────────────────────────────────────

/// Tappable row that opens a time picker for the diary-reminder hour.
class _NotifTimeTile extends StatelessWidget {
  final int hour;
  final ValueChanged<int> onChanged;
  const _NotifTimeTile({required this.hour, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        '${hour.toString().padLeft(2, '0')}:00';
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
          helpText: 'リマインダー時刻',
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'リマインダー時刻',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 6),
                  Icon(Icons.access_time,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

