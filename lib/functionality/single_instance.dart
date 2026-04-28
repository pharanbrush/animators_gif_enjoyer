import 'package:shared_preferences/shared_preferences.dart';

const allowMultipleInstancesKey = 'allow_multiple_instances';

void storeAllowMultipleInstancePreference(bool useSingleInstance) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(allowMultipleInstancesKey, useSingleInstance);
}

Future<bool> getAllowMultipleInstancePreference({
  bool defaultAllowMultipleInstances = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final storedValue = prefs.getBool(allowMultipleInstancesKey);
  if (storedValue == null) return defaultAllowMultipleInstances;

  return storedValue;
}
