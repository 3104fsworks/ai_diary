import 'package:http/http.dart' as http;

import 'app_user.dart';

/// Authentication bridge. Implementations:
///   • [MockAuthService] for development / Web previews
///   • RealFirebaseAuthService for Android/iOS production
abstract class AuthService {
  /// Currently signed-in user, or null when signed out.
  AppUser? get currentUser;

  /// Streams user state changes so the UI can react to sign-in/out.
  Stream<AppUser?> get userChanges;

  Future<AppUser?> signInWithGoogle();

  Future<AppUser?> signInWithApple();

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// True when the current user signed in via Google — only then can we
  /// ask for extra OAuth scopes (Calendar, Tasks, etc.).
  bool get isGoogleUser;

  /// Ask the OS for additional Google OAuth scopes. Returns true on grant.
  /// Use the constants in [GoogleApiScopes] for the [scopes] parameter.
  Future<bool> requestGoogleScopes(List<String> scopes);

  /// HTTP client whose `Authorization: Bearer ...` header carries the
  /// signed-in Google user's access token. Returns null when no Google
  /// session is available. Caller is responsible for `close()`.
  Future<http.Client?> authenticatedGoogleClient();
}

/// Centralised Google OAuth scope strings. Keeps "what we ask for" in one
/// place so the auth + service layers stay in sync.
class GoogleApiScopes {
  GoogleApiScopes._();
  static const calendarReadonly =
      'https://www.googleapis.com/auth/calendar.readonly';
  static const tasksReadonly =
      'https://www.googleapis.com/auth/tasks.readonly';
}

/// Thrown by [AuthService] implementations so the UI can surface a
/// short, user-facing reason without leaking Firebase-specific types.
class AuthException implements Exception {
  final AuthFailure kind;
  final String? message;
  const AuthException(this.kind, [this.message]);

  @override
  String toString() => 'AuthException($kind${message == null ? '' : ': $message'})';
}

enum AuthFailure {
  cancelled,
  invalidEmail,
  invalidPassword,
  weakPassword,
  emailAlreadyInUse,
  userNotFound,
  wrongPassword,
  networkError,
  notConfigured,
  unknown,
}
