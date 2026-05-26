import 'package:flutter/material.dart';

import '../../app/app_settings.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/goal_item.dart';
import '../../l10n/generated/app_localizations.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late List<GoalItem> _goals;
  late AppSettings _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = AppSettingsScope.of(context);
    _goals = List.of(_settings.customGoals);
  }

  int get _maxGoals => _settings.isPremium ? 6 : 3;

  Future<void> _save() async {
    await _settings.setCustomGoals(_goals);
  }

  Future<void> _editGoal({GoalItem? existing}) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: existing?.label ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.goalsTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l.goalsNamePlaceholder,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.commonSave),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    setState(() {
      if (existing == null) {
        _goals.add(GoalItem(
          id: 'u-${DateTime.now().millisecondsSinceEpoch}',
          label: result,
        ));
      } else {
        final i = _goals.indexWhere((g) => g.id == existing.id);
        if (i >= 0) _goals[i] = existing.copyWith(label: result);
      }
    });
    await _save();
  }

  Future<void> _delete(GoalItem g) async {
    setState(() => _goals.removeWhere((x) => x.id == g.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canAdd = _goals.length < _maxGoals;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsGoals)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Text(l.goalsHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            _settings.isPremium ? l.goalsLimitPremium : l.goalsLimitFree,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final g in _goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        goalDisplayLabel(context, g),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l.commonSave,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editGoal(existing: g),
                    ),
                    IconButton(
                      tooltip: l.goalsDelete,
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _delete(g),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: canAdd ? () => _editGoal() : null,
            icon: const Icon(Icons.add, size: 20),
            label: Text(l.goalsAdd),
          ),
        ],
      ),
    );
  }

}
