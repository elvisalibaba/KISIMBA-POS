import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';
import 'phone_number.dart';

class LocalAuthStore implements AuthStore {
  LocalAuthStore({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences>? preferences,
  }) : _secure = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferences.getInstance();

  final FlutterSecureStorage _secure;
  final Future<SharedPreferences> _preferences;
  static const _accountKey = 'local_account_v1';
  static const _pinKey = 'local_pin_verifier_v1';

  @override
  Future<LocalAccount?> get account async {
    final raw = (await _preferences).getString(_accountKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return LocalAccount(
      phoneNumber: json['phone_number'] as String,
      fullName: json['full_name'] as String,
      businessName: json['business_name'] as String,
      businessType: json['business_type'] as String? ?? 'Boutique / Alimentation',
      businessAddress: json['business_address'] as String?,
    );
  }

  @override
  Future<LocalAccount> register(RegistrationData data) async {
    final normalized = normalizeCongolesePhone(data.phoneNumber);
    if (normalized == null) throw const FormatException('Numéro invalide');
    final current = await account;
    if (current != null && current.phoneNumber == normalized) {
      throw StateError('Ce numéro possède déjà un compte sur ce téléphone.');
    }
    final salt = _randomSalt();
    await _secure.write(
      key: _pinKey,
      value: '$salt:${_derivePin(data.pin, salt)}',
    );
    final result = LocalAccount(
      phoneNumber: normalized,
      fullName: data.fullName.trim(),
      businessName: data.businessName.trim(),
      businessType: data.businessType,
      businessAddress: [data.neighborhood, data.commune, data.city]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(', '),
    );
    await (await _preferences).setString(
      _accountKey,
      jsonEncode({
        'phone_number': result.phoneNumber,
        'full_name': result.fullName,
        'business_name': result.businessName,
        'business_address': result.businessAddress,
        'business_type': result.businessType,
        'city': data.city,
        'commune': data.commune,
        'neighborhood': data.neighborhood,
        'primary_currency': data.primaryCurrency,
      }),
    );
    return result;
  }

  @override
  Future<bool> unlock(String phoneNumber, String pin) async {
    final saved = await account;
    if (saved == null ||
        normalizeCongolesePhone(phoneNumber) != saved.phoneNumber) {
      return false;
    }
    final stored = await _secure.read(key: _pinKey);
    if (stored == null || !stored.contains(':')) return false;
    final separator = stored.indexOf(':');
    final salt = stored.substring(0, separator);
    return _constantTimeEquals(
      _derivePin(pin, salt),
      stored.substring(separator + 1),
    );
  }

  @override
  Future<void> lock() async {}

  String _randomSalt() => base64UrlEncode(
    List<int>.generate(24, (_) => Random.secure().nextInt(256)),
  );

  String _derivePin(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt:$pin');
    for (var i = 0; i < 120000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64UrlEncode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
