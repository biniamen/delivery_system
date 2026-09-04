import 'package:creavers_delivery_mobile/core/models/auth_session.dart';

final class CustomerOtpChallenge {
  const CustomerOtpChallenge({
    required this.challengeId,
    required this.maskedPhoneNumber,
    required this.expiresAtUtc,
    this.developmentCode,
  });

  factory CustomerOtpChallenge.fromJson(Map<String, Object?> json) =>
      CustomerOtpChallenge(
        challengeId: json['challengeId']! as String,
        maskedPhoneNumber: json['maskedPhoneNumber']! as String,
        expiresAtUtc: DateTime.parse(json['expiresAtUtc']! as String).toUtc(),
        developmentCode: json['developmentCode'] as String?,
      );

  final String challengeId;
  final String maskedPhoneNumber;
  final DateTime expiresAtUtc;
  final String? developmentCode;
}

final class CustomerOtpVerification {
  const CustomerOtpVerification({
    required this.requiresProfile,
    this.verifiedChallengeId,
    this.session,
  });

  factory CustomerOtpVerification.fromJson(Map<String, Object?> json) =>
      CustomerOtpVerification(
        requiresProfile: json['requiresProfile']! as bool,
        verifiedChallengeId: json['verifiedChallengeId'] as String?,
        session: json['session'] is Map<String, Object?>
            ? AuthSession.fromJson(json['session']! as Map<String, Object?>)
            : null,
      );

  final bool requiresProfile;
  final String? verifiedChallengeId;
  final AuthSession? session;
}
