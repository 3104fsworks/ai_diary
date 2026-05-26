/// What an invite code grants once redeemed.
enum InviteReward {
  /// Permanent free access — for influencers, beta testers, etc.
  /// Distributed one-time-use codes (`AID-FREE-XXXX`).
  lifetime,

  /// 1-month free — both the inviter and invitee receive this when
  /// a generic referral code is used (`AID-1MO-XXXX`).
  oneMonth,
}

class InviteCheckResult {
  /// `true` if the code matched a known valid invite.
  final bool valid;

  /// `true` if the code matched but has already been used by this device.
  final bool alreadyUsed;

  /// What this code grants (only set when [valid] is true).
  final InviteReward? reward;

  const InviteCheckResult.valid(this.reward)
      : valid = true,
        alreadyUsed = false;
  const InviteCheckResult.duplicate()
      : valid = true,
        alreadyUsed = true,
        reward = null;
  const InviteCheckResult.invalid()
      : valid = false,
        alreadyUsed = false,
        reward = null;
}

/// Validates user-entered invite codes.
///
/// For the MVP this is a static list — when Firebase is wired up, replace
/// the body of [check] with a Firestore lookup against the `invite_codes`
/// collection. The shape of the return value stays the same.
class InviteCodeService {
  InviteCodeService({String? alreadyRedeemed})
      : _alreadyRedeemed = alreadyRedeemed?.trim().toUpperCase();

  final String? _alreadyRedeemed;

  /// Hardcoded permanent-free codes. Replace with Firestore later.
  /// One-time-use semantics are enforced via [alreadyRedeemed].
  static const _permanentCodes = <String>{
    'AID-FREE-X3K2-9MZP',
    'AID-FREE-7QFE-T8WL',
    'AID-FREE-B2PR-N5DK',
    'AID-FREE-A9LM-J4XC',
    'AID-FREE-V6HG-Y1TZ',
  };

  /// Hardcoded test 1-month codes. In production these will be issued
  /// per inviter (each user gets a unique generic code to share).
  static const _oneMonthCodes = <String>{
    'AID-1MO-TEST-0001',
    'AID-1MO-TEST-0002',
    'AID-1MO-TEST-0003',
  };

  InviteCheckResult check(String code) {
    final normalised = code.trim().toUpperCase();
    if (normalised.isEmpty) return const InviteCheckResult.invalid();

    if (_alreadyRedeemed != null && _alreadyRedeemed == normalised) {
      return const InviteCheckResult.duplicate();
    }

    if (_permanentCodes.contains(normalised)) {
      return const InviteCheckResult.valid(InviteReward.lifetime);
    }
    if (_oneMonthCodes.contains(normalised)) {
      return const InviteCheckResult.valid(InviteReward.oneMonth);
    }
    return const InviteCheckResult.invalid();
  }
}
