import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/invites/invite_code_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// Shown between login and the survey. Optional — users without a code
/// just tap "持っていません" to continue.
class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _redeeming = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final settings = AppSettingsScope.of(context);
    final l = AppLocalizations.of(context);
    final service = InviteCodeService(alreadyRedeemed: settings.redeemedCode);

    setState(() {
      _redeeming = true;
      _error = null;
    });

    final result = service.check(_controller.text);

    if (!result.valid) {
      setState(() {
        _redeeming = false;
        _error = l.inviteInvalid;
      });
      return;
    }
    if (result.alreadyUsed) {
      setState(() {
        _redeeming = false;
        _error = l.inviteAlreadyUsed;
      });
      return;
    }

    final code = _controller.text.trim().toUpperCase();
    switch (result.reward!) {
      case InviteReward.lifetime:
        await settings.grantLifetimeFree(redeemedCode: code);
        if (!mounted) return;
        await _showSuccess(l.inviteSuccessLifetime);
        break;
      case InviteReward.oneMonth:
        await settings.grantTimedPremium(
          duration: const Duration(days: 30),
          redeemedCode: code,
        );
        if (!mounted) return;
        await _showSuccess(l.inviteSuccessMonth);
        break;
    }

    if (!mounted) return;
    context.go(AppRoutes.survey);
  }

  Future<void> _showSuccess(String message) async {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          icon: Icon(
            Icons.celebration_outlined,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.inviteContinue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _skip() => context.go(AppRoutes.survey);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(l.inviteTitle, style: theme.textTheme.displayLarge),
              const SizedBox(height: 12),
              Text(
                l.inviteSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(
                    color: _error != null
                        ? theme.colorScheme.error
                        : theme.dividerColor,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\-]'),
                    ),
                  ],
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(letterSpacing: 1.5),
                  decoration: InputDecoration(hintText: l.inviteHint),
                  onSubmitted: (_) => _redeem(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _redeeming ? null : _redeem,
                child: Text(l.inviteRedeem),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skip,
                child: Text(l.inviteSkip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
