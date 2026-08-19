import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_store.dart';

class SupabaseOtpVerifier implements OtpVerifier {
  SupabaseOtpVerifier(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> isAvailable() async {
    try {
      await _client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sendCode(String normalizedPhoneNumber) =>
      _client.auth.signInWithOtp(
        phone: normalizedPhoneNumber,
        shouldCreateUser: true,
        channel: OtpChannel.sms,
      );

  @override
  Future<bool> verifyCode(String normalizedPhoneNumber, String code) async {
    final response = await _client.auth.verifyOTP(
      phone: normalizedPhoneNumber,
      token: code,
      type: OtpType.sms,
    );
    return response.user != null && response.session != null;
  }
}
