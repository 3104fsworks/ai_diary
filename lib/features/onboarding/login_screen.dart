import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../core/auth/app_user.dart';
import '../../core/auth/auth_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/google_sign_in_button.dart';

enum _AuthProvider { google, apple }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _AuthProvider? _busy;

  bool get _showApple {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _signIn(_AuthProvider provider) async {
    if (_busy != null) return;
    setState(() => _busy = provider);

    final services = Services.of(context);
    final settings = AppSettingsScope.of(context);
    final l = AppLocalizations.of(context);

    AppUser? user;
    try {
      user = switch (provider) {
        _AuthProvider.google => await services.auth.signInWithGoogle(),
        _AuthProvider.apple => await services.auth.signInWithApple(),
      };
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = null);
      if (e.kind != AuthFailure.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.loginSignInFailed)),
        );
      }
      return;
    } catch (_) {
      user = null;
    }

    if (!mounted) return;
    setState(() => _busy = null);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.loginSignInFailed)),
      );
      return;
    }
    await settings.setCurrentUserId(user.uid);
    if (!mounted) return;
    context.go(AppRoutes.invite);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(l.loginWelcome, style: theme.textTheme.displayLarge),
              const SizedBox(height: 12),
              Text(
                l.loginSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 24),
              _PrivacyNote(
                title: l.loginPrivacyTitle,
                body: l.loginPrivacyBody,
              ),
              const SizedBox(height: 20),
              GoogleSignInButton(
                label: l.loginWithGoogle,
                onPressed: () => _signIn(_AuthProvider.google),
              ),
              if (_showApple) ...[
                const SizedBox(height: 12),
                _AppleSignInButton(
                  label: l.loginWithApple,
                  onPressed: () => _signIn(_AuthProvider.apple),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy != null
                    ? null
                    : () => context.push(AppRoutes.emailLogin),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                ),
                child: Text(l.loginWithEmailSignIn),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy != null
                    ? null
                    : () => context.push(AppRoutes.emailLogin, extra: true),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(l.loginWithEmailSignUp),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _AppleSignInButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? Colors.black : Colors.white;
    final fg = isLight ? Colors.white : Colors.black;
    return SizedBox(
      height: 56,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, color: fg, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  final String title;
  final String body;
  const _PrivacyNote({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
