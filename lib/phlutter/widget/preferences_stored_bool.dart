import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../phdart/command_rate_limiter.dart';

class PreferencesStoredBool {
  PreferencesStoredBool({
    required String preferenceKey,
    required bool defaultValue,
    this.onLog,
  }) : _preferenceKey = preferenceKey,
       _defaultValue = defaultValue {
    valueNotifier.addListener(() => storeInPreferences(value));
  }

  final bool _defaultValue;
  final String _preferenceKey;
  final void Function(String log)? onLog;

  final limiter = CommandRateLimiter();
  final valueNotifier = ValueNotifier(false);
  bool isLoaded = false;

  bool get value => valueNotifier.value;

  String get logPrefix => "[preferences_stored_bool][\"$_preferenceKey\"]";

  void dispose() {
    valueNotifier.dispose();
  }

  Future<void> loadFromPreferences() async {
    final loadedValue = await _getPreferenceBool(
      key: _preferenceKey,
      defaultValue: _defaultValue,
    );

    valueNotifier.value = loadedValue;
    isLoaded = true;
    onLog?.call("$logPrefix $loadedValue was loaded.");
  }

  Future<void> storeInPreferences(bool newValue) {
    if (!isLoaded) {
      onLog?.call(
        "[X] $logPrefix Stored but was not initialized from preferences.\n"
        "Make sure .loadFromPreferences was called on startup.",
      );
    }
    return limiter.queueCommand(
      () async {
        await _setPreferenceBool(
          key: _preferenceKey,
          value: newValue,
        );
        onLog?.call("$logPrefix $newValue was stored.");
      },
    );
  }
}

Future<bool> _getPreferenceBool({
  required String key,
  bool defaultValue = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key) ?? defaultValue;
}

Future<void> _setPreferenceBool({
  required String key,
  required bool value,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}
