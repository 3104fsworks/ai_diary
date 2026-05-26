import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

class GoalItem {
  final String id;
  /// User-typed label. Falls back to translating [labelKey] when null/empty.
  final String? label;
  /// Reserved for default/built-in goals (`goalSteps`, `goalThanks`, etc.).
  /// Kept for backward compatibility — new user goals leave this null.
  final String labelKey;
  final bool checked;

  const GoalItem({
    required this.id,
    this.label,
    this.labelKey = '',
    this.checked = false,
  });

  GoalItem copyWith({bool? checked, String? label}) => GoalItem(
        id: id,
        label: label ?? this.label,
        labelKey: labelKey,
        checked: checked ?? this.checked,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (label != null) 'label': label,
        if (labelKey.isNotEmpty) 'labelKey': labelKey,
        'checked': checked,
      };

  factory GoalItem.fromJson(Map<String, dynamic> j) => GoalItem(
        id: j['id'] as String,
        label: j['label'] as String?,
        labelKey: (j['labelKey'] as String?) ?? '',
        checked: (j['checked'] as bool?) ?? false,
      );
}

/// Resolves the user-facing label for a goal. Custom user goals (label set,
/// labelKey empty) win; otherwise we translate the built-in [labelKey].
String goalDisplayLabel(BuildContext context, GoalItem g) {
  if (g.label != null && g.label!.isNotEmpty) return g.label!;
  final l = AppLocalizations.of(context);
  return switch (g.labelKey) {
    'goalSteps' => l.goalSteps,
    'goalNoMoney' => l.goalNoMoney,
    'goalThanks' => l.goalThanks,
    'goalSmile' => l.goalSmile,
    'goalRead' => l.goalRead,
    'goalSleep' => l.goalSleep,
    _ => g.labelKey,
  };
}
