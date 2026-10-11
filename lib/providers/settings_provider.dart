import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/speed_mode.dart';

/// Preferencias da transferencia: velocidade e opcao de pular duplicadas.
class SettingsProvider extends ChangeNotifier {
  static const _speedKey = 'speed_mode';
  static const _skipKey = 'skip_existing';

  SpeedMode _speed = SpeedMode.normal;
  bool _skipExisting = true;

  SpeedMode get speed => _speed;
  bool get skipExisting => _skipExisting;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _speed = SpeedModeX.fromName(prefs.getString(_speedKey));
    _skipExisting = prefs.getBool(_skipKey) ?? true;
    notifyListeners();
  }

  Future<void> setSpeed(SpeedMode speed) async {
    _speed = speed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_speedKey, speed.storageName);
  }

  Future<void> setSkipExisting(bool value) async {
    _skipExisting = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipKey, value);
  }
}
