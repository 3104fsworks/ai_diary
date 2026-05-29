import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../core/export/bulk_markdown_exporter.dart';
import '../../l10n/generated/app_localizations.dart';

/// Advanced / power-user settings screen ("カスタム").
/// Contains AI API key, Obsidian sync, Markdown export, and data migration.
class CustomSettingsScreen extends StatefulWidget {
  const CustomSettingsScreen({super.key});

  @override
  State<CustomSettingsScreen> createState() => _CustomSettingsScreenState();
}

class _CustomSettingsScreenState extends State<CustomSettingsScreen> {
  bool _autoSyncOn = true;

  // ── Proxy settings dialogs ────────────────────────────────────────────────

  Future<void> _editProxyUrl(
    BuildContext context,
    AppSettings settings,
  ) async {
    final controller = TextEditingController(text: settings.proxyBaseUrl);
    final result = await showDialog<_KeyDialogResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('プロキシURL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://ai-diary-proxy.you.workers.dev',
            border: OutlineInputBorder(),
            helperText: 'Cloudflare WorkersのURL。空にするとAPIに直接接続します。',
            helperMaxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, const _KeyDialogResult.clear()),
            child: const Text('クリア'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _KeyDialogResult.save(controller.text)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    await settings.setProxyBaseUrl(result.clear ? '' : (result.value ?? ''));
  }

  Future<void> _editProxyToken(
    BuildContext context,
    AppSettings settings,
  ) async {
    final controller = TextEditingController(text: settings.appProxyToken);
    final result = await showDialog<_KeyDialogResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アプリトークン'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Worker の APP_TOKEN に設定した文字列',
            border: OutlineInputBorder(),
            helperText: 'X-App-Token ヘッダーとして送信されます。未設定でも動作します。',
            helperMaxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, const _KeyDialogResult.clear()),
            child: const Text('クリア'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _KeyDialogResult.save(controller.text)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    await settings.setAppProxyToken(result.clear ? '' : (result.value ?? ''));
  }

  Future<void> _editApiKey(
    BuildContext context,
    AppSettings settings,
    AppLocalizations l,
  ) async {
    final controller = TextEditingController(text: settings.geminiApiKey);
    final result = await showDialog<_KeyDialogResult>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () =>
                Navigator.pop(ctx, _KeyDialogResult.save(controller.text)),
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result.clear) {
      await settings.setGeminiApiKey('');
    } else {
      await settings.setGeminiApiKey(result.value ?? '');
    }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('カスタム設定')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          // 1. AI API key (Gemini / BYOK)
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

          // 2. Proxy settings (Cloudflare Workers API key migration)
          const _SectionHeader(label: 'プロキシ設定'),
          _ListTile(
            label: 'プロキシURL',
            subtitle: settings.proxyBaseUrl.isEmpty
                ? '未設定（APIに直接接続）'
                : settings.proxyBaseUrl,
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _editProxyUrl(context, settings),
          ),
          _ListTile(
            label: 'アプリトークン',
            subtitle: settings.appProxyToken.isEmpty
                ? '未設定'
                : '設定済み（${'•' * 8}）',
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _editProxyToken(context, settings),
          ),

          // 3. Sync (Obsidian / cloud)
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

          // 3. Export / Migration
          _SectionHeader(label: 'データ管理'),
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared sub-widgets (copied from settings_screen.dart)
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                      style: theme.textTheme.bodySmall
                          ?.copyWith(height: 1.5),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: theme.textTheme.bodyLarge)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DiaryFolderTile extends StatefulWidget {
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
  State<_DiaryFolderTile> createState() => _DiaryFolderTileState();
}

class _DiaryFolderTileState extends State<_DiaryFolderTile> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(widget.hint,
              style:
                  theme.textTheme.bodySmall?.copyWith(height: 1.5)),
          if (widget.path != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.path!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Copy path to clipboard
                    await Future.delayed(Duration.zero);
                    setState(() => _copied = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _copied = false);
                    });
                  },
                  child: Text(
                      _copied ? widget.copiedLabel : widget.copyLabel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: theme.textTheme.bodyMedium),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
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
                Expanded(
                    child:
                        Text(label, style: theme.textTheme.bodyLarge)),
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
            Text(help,
                style: theme.textTheme.bodySmall
                    ?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _KeyDialogResult {
  final bool clear;
  final String? value;
  const _KeyDialogResult._({required this.clear, this.value});
  const _KeyDialogResult.clear() : this._(clear: true);
  const _KeyDialogResult.save(String v)
      : this._(clear: false, value: v);
}
