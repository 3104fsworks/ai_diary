import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../data/models/goal_item.dart';

typedef GoalLabelResolver = String Function(GoalItem g);

class GoalGrid extends StatelessWidget {
  final List<GoalItem> goals;
  final ValueChanged<int> onToggle;
  final GoalLabelResolver labelOf;

  const GoalGrid({
    super.key,
    required this.goals,
    required this.onToggle,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.4,
      children: [
        for (var i = 0; i < goals.length; i++)
          _GoalTile(
            label: labelOf(goals[i]),
            checked: goals[i].checked,
            onTap: () => onToggle(i),
          ),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const _GoalTile({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color:
                checked ? theme.colorScheme.primary : theme.dividerColor,
            width: checked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              checked
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              size: 20,
              color: checked
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
