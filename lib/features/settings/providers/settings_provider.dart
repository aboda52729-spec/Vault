import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';

final settingsStateProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);
  return SettingsNotifier(settings, auth);
});

class SettingsState {
  final bool isArabic;
  final bool hasPin;
  final bool canUseBiometrics;
  final bool showBalanceOnLock;

  const SettingsState({
    this.isArabic = true,
    this.hasPin = false,
    this.canUseBiometrics = false,
    this.showBalanceOnLock = false,
  });

  SettingsState copyWith({
    bool? isArabic,
    bool? hasPin,
    bool? canUseBiometrics,
    bool? showBalanceOnLock,
  }) {
    return SettingsState(
      isArabic: isArabic ?? this.isArabic,
      hasPin: hasPin ?? this.hasPin,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      showBalanceOnLock: showBalanceOnLock ?? this.showBalanceOnLock,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _settings;
  final AuthRepository _auth;

  SettingsNotifier(this._settings, this._auth) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _auth.hasPin();
    final canBio = await _auth.canCheckBiometrics();
    state = state.copyWith(
      isArabic: _settings.isArabic,
      hasPin: hasPin,
      canUseBiometrics: canBio,
    );
  }

  Future<void> toggleLanguage() async {
    _settings.isArabic = !state.isArabic;
    state = state.copyWith(isArabic: !state.isArabic);
  }

  Future<void> setPin(String pin) async {
    await _auth.setPin(pin);
    state = state.copyWith(hasPin: true);
  }

  Future<void> removePin() async {
    await _auth.removePin();
    state = state.copyWith(hasPin: false);
  }
}
