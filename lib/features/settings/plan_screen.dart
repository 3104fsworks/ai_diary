import 'package:flutter/material.dart';

import '../../app/app_settings.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../core/purchase/product_info.dart';
import '../../l10n/generated/app_localizations.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _busy = false;

  Future<void> _purchase(String productId, String displayName) async {
    if (_busy) return;
    setState(() => _busy = true);

    final l = AppLocalizations.of(context);
    final services = Services.of(context);
    final settings = AppSettingsScope.of(context);

    final result = await services.purchase.purchase(productId);

    if (!mounted) return;
    setState(() => _busy = false);

    switch (result.status) {
      case PurchaseStatus.success:
        await settings.setPremium(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.planPurchaseSuccess(displayName))),
        );
      case PurchaseStatus.cancelled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.planPurchaseCancelled)),
        );
      case PurchaseStatus.error:
      case PurchaseStatus.pending:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.planPurchaseError)),
        );
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final services = Services.of(context);
    final result = await services.purchase.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.status == PurchaseStatus.success) {
      final settings = AppSettingsScope.of(context);
      await settings.setPremium(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = AppSettingsScope.of(context);

    final plans = [
      _Plan(
        productId: null, // free
        name: l.planFree,
        monthly: '¥0',
        yearly: null,
        features: const [
          'テキスト手入力で日記をつける',
          'ObsidianやNotion等へのエクスポート',
          '目標タスク 3個まで',
          '広告あり',
        ],
      ),
      _Plan(
        productId: 'ai_journal_voice_monthly',
        name: l.planVoice,
        monthly: '¥300${l.planPerMonth}',
        yearly: '¥2,900${l.planPerYear}',
        inheritsFrom: l.planFree,
        features: const [
          '音声入力でAI日記自動生成',
          'すべての広告を削除',
        ],
      ),
      _Plan(
        productId: 'ai_journal_voice_photo_monthly',
        name: l.planVoicePhoto,
        monthly: '¥500${l.planPerMonth}',
        yearly: '¥4,900${l.planPerYear}',
        inheritsFrom: l.planVoice,
        features: const [
          '写真アップロード（自動軽量化）',
          'AIによる写真の説明文生成',
        ],
      ),
      _Plan(
        productId: 'ai_journal_full_monthly',
        name: l.planFull,
        monthly: '¥1,000${l.planPerMonth}',
        yearly: '¥9,800${l.planPerYear}',
        inheritsFrom: l.planVoicePhoto,
        features: const [
          'ヘルスケア（歩数・睡眠）自動連携',
          'カレンダー・ToDoの自動連携',
          '位置情報タイムライン',
          '目標タスク 6個まで',
          'AIの口調を3種類から選択',
        ],
        highlight: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsUpgrade)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Text(l.planCurrent, style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                Text(
                  settings.isPremium ? l.planPremiumLabel : l.planFreeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: settings.isPremium
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              l.planFreeTrial,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          for (final p in plans) ...[
            _PlanCard(
              plan: p,
              busy: _busy,
              subscribeLabel: l.planSubscribe,
              onSubscribe: p.productId == null
                  ? null
                  : () => _purchase(p.productId!, p.name),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _restore,
            child: Text(l.planRestore),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => settings.setPremium(!settings.isPremium),
            child: Text(
              settings.isPremium ? l.planTestDisable : l.planTestEnable,
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String? productId; // null = free
  final String name;
  final String monthly;
  final String? yearly;
  final String? inheritsFrom;
  final List<String> features;
  final bool highlight;
  const _Plan({
    required this.productId,
    required this.name,
    required this.monthly,
    required this.yearly,
    required this.features,
    this.inheritsFrom,
    this.highlight = false,
  });
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool busy;
  final String subscribeLabel;
  final VoidCallback? onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.busy,
    required this.subscribeLabel,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: plan.highlight
              ? theme.colorScheme.primary
              : theme.dividerColor,
          width: plan.highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.name, style: theme.textTheme.titleLarge),
              const Spacer(),
              Text(plan.monthly, style: theme.textTheme.titleMedium),
            ],
          ),
          if (plan.yearly != null) ...[
            const SizedBox(height: 4),
            Text(plan.yearly!, style: theme.textTheme.bodySmall),
          ],
          if (plan.inheritsFrom != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Text(
                '「${plan.inheritsFrom}」の全機能 + 以下',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (final f in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          if (onSubscribe != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : onSubscribe,
                child: Text(subscribeLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
