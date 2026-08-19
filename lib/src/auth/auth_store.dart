class RegistrationData {
  const RegistrationData({
    required this.phoneNumber,
    required this.fullName,
    required this.businessName,
    required this.businessType,
    required this.pin,
    this.city,
    this.commune,
    this.neighborhood,
    this.primaryCurrency = 'CDF',
  });
  final String phoneNumber;
  final String fullName;
  final String businessName;
  final String businessType;
  final String pin;
  final String? city;
  final String? commune;
  final String? neighborhood;
  final String primaryCurrency;
}

class LocalAccount {
  const LocalAccount({
    required this.phoneNumber,
    required this.fullName,
    required this.businessName,
    this.businessAddress,
  });
  final String phoneNumber;
  final String fullName;
  final String businessName;
  final String? businessAddress;
}

abstract class AuthStore {
  Future<LocalAccount?> get account;
  Future<LocalAccount> register(RegistrationData data);
  Future<bool> unlock(String phoneNumber, String pin);
  Future<void> lock();
}

/// A network implementation can use Supabase Phone Auth. Registration remains
/// usable when this service is unavailable and can be verified later.
abstract class OtpVerifier {
  Future<bool> isAvailable();
  Future<void> sendCode(String normalizedPhoneNumber);
  Future<bool> verifyCode(String normalizedPhoneNumber, String code);
}
