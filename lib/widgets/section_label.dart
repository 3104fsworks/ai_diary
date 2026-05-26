import 'package:flutter/material.dart';

/// Minimal section divider — small label with a hairline rule.
class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          letterSpacing: 2.4,
          color: theme.dividerColor == const Color(0xFFE0E0E0)
              ? const Color(0xFF757575)
              : const Color(0xFFA8A8A8),
        ),
      ),
    );
  }
}
