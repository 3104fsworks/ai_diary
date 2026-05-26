import 'dart:async';

import 'package:http/http.dart' as http;

import 'app_user.dart';
import 'auth_service.dart';

/// Stand-in until Firebase is wired up. Every sign-in returns a stable
/// mock user so the rest of the app — invite codes, settings, sign-out —
/// behaves exactly as it will in production.
class MockAuthService implements AuthService {
  AppUser? _user;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  AppUser _mockUser(String provider, {String? email}) => AppUser(
        uid: 'mock-$provider-${DateTime.now().millisecondsSinceEpoch}',
        email: email ?? (provider == 'google' ? 'demo@example.com' : null),
        displayName: 'Demo User',
      );

  @override
  Future<AppUser?> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = _mockUser('google');
    _controller.add(_user);
    return _user;
  }

  @override
  Future<AppUser?> signInWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = _mockUser('apple', email: 'demo@privaterelay.appleid.com');
    _controller.add(_user);
    return _user;
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = _mockUser('email', email: email);
    _controller.add(_user);
    return _user;
  }

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = _mockUser('email', email: email);
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  // Mock can't speak real Google APIs, so calendar/tasks fall back to
  // MockCalendarService / MockTasksService at the service_locator level.
  @override
  bool get isGoogleUser => false;

  @override
  Future<bool> requestGoogleScopes(List<String> scopes) async => false;

  @override
  Future<http.Client?> authenticatedGoogleClient() async => null;
}
