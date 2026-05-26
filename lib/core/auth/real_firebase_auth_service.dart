import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'app_user.dart';
import 'auth_service.dart';

/// Live implementation backed by Firebase Auth.
/// Supports Google, Apple, and Email+Password.
class RealFirebaseAuthService implements AuthService {
  RealFirebaseAuthService() : _auth = fb.FirebaseAuth.instance {
    _sub = _auth.authStateChanges().listen((u) {
      _controller.add(_fromFirebase(u));
    });
  }

  final fb.FirebaseAuth _auth;
  final _controller = StreamController<AppUser?>.broadcast();
  late final StreamSubscription<fb.User?> _sub;

  @override
  AppUser? get currentUser => _fromFirebase(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  AppUser? _fromFirebase(fb.User? u) {
    if (u == null) return null;
    return AppUser(
      uid: u.uid,
      email: u.email,
      displayName: u.displayName,
    );
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final google = GoogleSignIn();
      final account = await google.signIn();
      if (account == null) {
        throw const AuthException(AuthFailure.cancelled);
      }
      final tokens = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return _fromFirebase(result.user);
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code), e.message);
    } catch (e) {
      throw AuthException(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AppUser?> signInWithApple() async {
    try {
      final raw = _nonce();
      final hashedNonce = sha256.convert(utf8.encode(raw)).toString();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final credential = fb.OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: raw,
      );
      final result = await _auth.signInWithCredential(credential);
      // Apple only returns the display name on the very first sign-in.
      final fullName = [apple.givenName, apple.familyName]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      if (fullName.isNotEmpty && result.user?.displayName == null) {
        await result.user?.updateDisplayName(fullName);
      }
      return _fromFirebase(result.user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException(AuthFailure.cancelled);
      }
      throw AuthException(AuthFailure.unknown, e.message);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code), e.message);
    } catch (e) {
      throw AuthException(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _fromFirebase(result.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code), e.message);
    } catch (e) {
      throw AuthException(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _fromFirebase(result.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code), e.message);
    } catch (e) {
      throw AuthException(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseCode(e.code), e.message);
    } catch (e) {
      throw AuthException(AuthFailure.unknown, e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    // Sign out of Google as well so the chooser is shown next time.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {/* ignored — user may not have signed in via Google */}
    await _auth.signOut();
  }

  @override
  bool get isGoogleUser {
    final providers = _auth.currentUser?.providerData ?? const [];
    return providers.any((p) => p.providerId == 'google.com');
  }

  @override
  Future<bool> requestGoogleScopes(List<String> scopes) async {
    try {
      final google = GoogleSignIn(scopes: scopes);
      // Re-sign-in silently first so we keep the same account context.
      var account = await google.signInSilently();
      account ??= await google.signIn();
      if (account == null) return false;
      // requestScopes pops the OS consent sheet for the new scopes only.
      return await google.requestScopes(scopes);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<http.Client?> authenticatedGoogleClient() async {
    try {
      final google = GoogleSignIn();
      final account = google.currentUser ?? await google.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      final token = auth.accessToken;
      if (token == null) return null;
      return _BearerClient(http.Client(), token);
    } catch (_) {
      return null;
    }
  }

  /// Whether Apple sign-in is available on the current platform.
  /// iOS 13+ / macOS — Android falls back to a web flow which we don't ship.
  static bool get isAppleAvailable {
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  AuthFailure _mapFirebaseCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthFailure.invalidEmail;
      case 'user-disabled':
      case 'user-not-found':
        return AuthFailure.userNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.wrongPassword;
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse;
      case 'weak-password':
        return AuthFailure.weakPassword;
      case 'network-request-failed':
        return AuthFailure.networkError;
      default:
        return AuthFailure.unknown;
    }
  }

  /// RFC 4122-ish random nonce — only needs to be unguessable, not strictly UUID.
  String _nonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => charset[rand.nextInt(charset.length)])
        .join();
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}

/// Wraps an http.Client and stamps every outgoing request with the
/// signed-in Google user's bearer token. Used by RealGoogleCalendarService
/// and RealGoogleTasksService.
class _BearerClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;
  _BearerClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
