import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/models/customer_onboarding.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class CustomerOnboardingService {
  Future<CustomerOtpChallenge> requestOtp(String phoneNumber);

  Future<CustomerOtpVerification> verifyOtp({
    required String challengeId,
    required String phoneNumber,
    required String otpCode,
  });

  Future<AuthSession> register({
    required String verifiedChallengeId,
    required String phoneNumber,
    required String fullName,
    required DateTime dateOfBirth,
  });
}

final class ApiCustomerOnboardingService implements CustomerOnboardingService {
  ApiCustomerOnboardingService(this._client);

  final ApiClient _client;

  @override
  Future<CustomerOtpChallenge> requestOtp(String phoneNumber) async {
    final response = await _client.post(
      'customer-onboarding/otp',
      authenticated: false,
      body: <String, Object?>{'phoneNumber': phoneNumber.trim()},
    );
    return CustomerOtpChallenge.fromJson(_map(response, 'OTP response'));
  }

  @override
  Future<CustomerOtpVerification> verifyOtp({
    required String challengeId,
    required String phoneNumber,
    required String otpCode,
  }) async {
    final response = await _client.post(
      'customer-onboarding/otp/verify',
      authenticated: false,
      body: <String, Object?>{
        'challengeId': challengeId,
        'phoneNumber': phoneNumber.trim(),
        'otpCode': otpCode.trim(),
      },
    );
    final verification = CustomerOtpVerification.fromJson(
      _map(response, 'OTP verification response'),
    );
    if (verification.session case final session?) {
      _client.accessToken = session.accessToken;
    }
    return verification;
  }

  @override
  Future<AuthSession> register({
    required String verifiedChallengeId,
    required String phoneNumber,
    required String fullName,
    required DateTime dateOfBirth,
  }) async {
    final date = dateOfBirth.toLocal();
    final response = await _client.post(
      'customer-onboarding/register',
      authenticated: false,
      body: <String, Object?>{
        'verifiedChallengeId': verifiedChallengeId,
        'phoneNumber': phoneNumber.trim(),
        'fullName': fullName.trim(),
        'dateOfBirth':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      },
    );
    final session = AuthSession.fromJson(
      _map(response, 'registration response'),
    );
    _client.accessToken = session.accessToken;
    return session;
  }

  Map<String, Object?> _map(Object? response, String label) {
    if (response is! Map<String, Object?>) {
      throw ApiException(message: 'The $label was not valid.');
    }
    return response;
  }
}
