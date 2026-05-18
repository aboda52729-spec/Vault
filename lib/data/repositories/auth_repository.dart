import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthRepository {
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';

  final FlutterSecureStorage _secure;

  AuthRepository(this._secure);

  Future<bool> hasPin() async {
    final hash = await _secure.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _secure.write(key: _pinHashKey, value: hash);
    await _secure.write(key: _pinSaltKey, value: salt);
  }

  Future<bool> verifyPin(String pin) async {
    final hash = await _secure.read(key: _pinHashKey);
    final salt = await _secure.read(key: _pinSaltKey);
    if (hash == null || salt == null) return false;
    return _hashPin(pin, salt) == hash;
  }

  Future<void> removePin() async {
    await _secure.delete(key: _pinHashKey);
    await _secure.delete(key: _pinSaltKey);
  }

  Future<bool> canCheckBiometrics() async {
    final auth = LocalAuthentication();
    return auth.canCheckBiometrics;
  }

  Future<bool> authenticateWithBiometrics() async {
    final auth = LocalAuthentication();
    try {
      return auth.authenticate(
        localizedReason: 'Unlock Vault to access your data',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final combined = pin + salt;
    final bytes = utf8.encode(combined);
    return base64.encode(bytes);
  }
}
