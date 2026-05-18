import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  bool get isArabic => _prefs.getBool('isArabic') ?? true;
  set isArabic(bool value) => _prefs.setBool('isArabic', value);

  bool get isFirstLaunch => _prefs.getBool('isFirstLaunch') ?? true;
  set isFirstLaunch(bool value) => _prefs.setBool('isFirstLaunch', value);

  bool get hasCompletedSetup => _prefs.getBool('hasCompletedSetup') ?? false;
  set hasCompletedSetup(bool value) => _prefs.setBool('hasCompletedSetup', value);
}
