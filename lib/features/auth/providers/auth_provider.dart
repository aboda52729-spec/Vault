import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});

enum AuthStatus { unknown, unlocked, locked }

class AuthState {
  final AuthStatus status;
  final bool hasPin;
  final bool canUseBiometrics;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.hasPin = false,
    this.canUseBiometrics = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? hasPin,
    bool? canUseBiometrics,
  }) {
    return AuthState(
      status: status ?? this.status,
      hasPin: hasPin ?? this.hasPin,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(const AuthState());

  Future<void> checkStatus() async {
    final hasPin = await _authRepo.hasPin();
    final canBio = await _authRepo.canCheckBiometrics();
    state = AuthState(
      status: hasPin ? AuthStatus.locked : AuthStatus.unlocked,
      hasPin: hasPin,
      canUseBiometrics: canBio,
    );
  }

  Future<bool> setPin(String pin) async {
    await _authRepo.setPin(pin);
    state = state.copyWith(hasPin: true, status: AuthStatus.unlocked);
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final valid = await _authRepo.verifyPin(pin);
    if (valid) {
      state = state.copyWith(status: AuthStatus.unlocked);
    }
    return valid;
  }

  Future<void> unlockWithBiometrics() async {
    final success = await _authRepo.authenticateWithBiometrics();
    if (success) {
      state = state.copyWith(status: AuthStatus.unlocked);
    }
  }

  Future<void> removePin() async {
    await _authRepo.removePin();
    state = state.copyWith(hasPin: false, status: AuthStatus.unlocked);
  }
}
