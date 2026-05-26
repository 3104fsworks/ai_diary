import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../core/auth/app_user.dart';
import '../../core/auth/auth_service.dart';
import '../../l10n/generated/app_localizations.dart';

class EmailLoginScreen extends StatefulWidget {
  /// Start in sign-up mode when the user came from the "新規登録" button.
  final bool startInSignUpMode;
  const EmailLoginScreen({super.key, this.startInSignUpMode = false});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late bool _isSignUp = widget.startInSignUpMode;
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);

    final services = Services.of(context);
    final settings = AppSettingsScope.of(context);
    final l = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    AppUser? user;
    try {
      user = _isSignUp
          ? await services.auth.signUpWithEmail(
              email: email,
              password: password,
            )
          : await services.auth.signInWithEmail(
              email: email,
              password: password,
            );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFor(e.kind, l))),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.authErrorGeneric)),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _busy = false);
    if (user == null) return;
    await settings.setCurrentUserId(user.uid);
    if (!mounted) return;
    context.go(AppRoutes.invite);
  }

  Future<void> _sendReset() async {
    final services = Services.of(context);
    final l = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailAuthResetEnterEmail)),
      );
      return;
    }
    try {
      await services.auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailAuthResetSent)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFor(e.kind, l))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.authErrorGeneric)),
      );
    }
  }

  String _messageFor(AuthFailure kind, AppLocalizations l) {
    return switch (kind) {
      AuthFailure.cancelled => l.loginCancelled,
      AuthFailure.invalidEmail => l.authErrorInvalidEmail,
      AuthFailure.invalidPassword || AuthFailure.wrongPassword =>
        l.authErrorWrongPassword,
      AuthFailure.weakPassword => l.authErrorWeakPassword,
      AuthFailure.emailAlreadyInUse => l.authErrorEmailInUse,
      AuthFailure.userNotFound => l.authErrorUserNotFound,
      AuthFailure.networkError => l.authErrorNetwork,
      AuthFailure.notConfigured => l.authErrorGeneric,
      AuthFailure.unknown => l.authErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? l.emailAuthSignUpTitle : l.emailAuthSignInTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ModeSegmented(
                  isSignUp: _isSignUp,
                  signInLabel: l.emailAuthSignInTitle,
                  signUpLabel: l.emailAuthSignUpTitle,
                  onChanged: (signUp) {
                    if (_busy) return;
                    setState(() => _isSignUp = signUp);
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l.emailAuthEmailLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty || !value.contains('@')) {
                      return l.authErrorInvalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: _isSignUp
                      ? const [AutofillHints.newPassword]
                      : const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: l.emailAuthPasswordLabel,
                    hintText: _isSignUp ? l.emailAuthPasswordHint : null,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (_isSignUp && value.length < 8) {
                      return l.authErrorWeakPassword;
                    }
                    if (!_isSignUp && value.isEmpty) {
                      return l.authErrorWrongPassword;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isSignUp
                                ? l.emailAuthSignUpButton
                                : l.emailAuthSignInButton,
                          ),
                  ),
                ),
                if (!_isSignUp) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : _sendReset,
                    child: Text(
                      l.emailAuthForgotPassword,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-segment "Sign in / Sign up" picker shown at the top of the form.
/// More visible than the tiny toggle link we used before.
class _ModeSegmented extends StatelessWidget {
  final bool isSignUp;
  final String signInLabel;
  final String signUpLabel;
  final ValueChanged<bool> onChanged;
  const _ModeSegmented({
    required this.isSignUp,
    required this.signInLabel,
    required this.signUpLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBg = theme.colorScheme.primary;
    final selectedFg = theme.colorScheme.onPrimary;
    final unselectedFg = theme.textTheme.bodyMedium?.color;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: signInLabel,
              selected: !isSignUp,
              fg: !isSignUp ? selectedFg : unselectedFg,
              bg: !isSignUp ? selectedBg : Colors.transparent,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: signUpLabel,
              selected: isSignUp,
              fg: isSignUp ? selectedFg : unselectedFg,
              bg: isSignUp ? selectedBg : Colors.transparent,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? fg;
  final Color bg;
  final VoidCallback onTap;
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
