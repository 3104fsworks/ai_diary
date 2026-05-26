/// A signed-in user, shaped for the app — not Firebase-specific so the
/// rest of the codebase doesn't import Firebase types.
class AppUser {
  /// Stable, anonymous identifier — used as the "who redeemed this code"
  /// reference, never as PII.
  final String uid;
  final String? email;
  final String? displayName;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
  });
}
