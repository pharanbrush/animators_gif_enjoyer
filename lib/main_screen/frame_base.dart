import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin FrameBaseStorer<T extends StatefulWidget> on State<T> {
  int _queuedFrameBaseSaveId = 0;

  int get displayFrameBaseOffset {
    return FrameBaseContext.of(context)?.frameBase.value ?? 0;
  }

  void _loadFrameBasePreference() async {
    final frameBaseContext = FrameBaseContext.of(context);
    if (frameBaseContext != null) {
      final preferencesBase = await getFrameBaseDisplayPreference() ?? 0;
      frameBaseContext.frameBase.value = preferencesBase;
      setState(() {});
    }
  }

  @override
  void initState() {
    void queueLoadPreference() async {
      await Future.delayed(const Duration(milliseconds: 20))
          .then((value) => _loadFrameBasePreference());
    }

    queueLoadPreference();
    super.initState();
  }

  void setDisplayFrameBase(int base) {
    if (base != 0) base = 1;
    setState(() {
      FrameBaseContext.of(context)?.frameBase.value = base;
    });

    void queueSaveThemetoPreferences() async {
      int getLatestSaveCommandId() => _queuedFrameBaseSaveId;
      int saveCommandId = DateTime.now().millisecondsSinceEpoch;
      _queuedFrameBaseSaveId = saveCommandId;

      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (getLatestSaveCommandId() != saveCommandId) return;
      }

      if (getLatestSaveCommandId() == saveCommandId) {
        storeFrameBaseDisplayPreference(base);
      }
    }

    queueSaveThemetoPreferences();
  }
}

class FrameBaseContext extends InheritedWidget {
  FrameBaseContext({
    super.key,
    required super.child,
    int initialValue = 0,
  }) : frameBase = ValueNotifier(initialValue);

  final ValueNotifier<int> frameBase;

  static FrameBaseContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FrameBaseContext>();
  }

  @override
  bool updateShouldNotify(FrameBaseContext oldWidget) => false;
}

//
// Frame base preference
//
const frameBasePreferenceKey = 'display_frame_base';

Future<int?> getFrameBaseDisplayPreference() async {
  final prefs = await SharedPreferences.getInstance();
  final retrievedDisplayPreference = prefs.getInt(frameBasePreferenceKey);
  return retrievedDisplayPreference ?? 0;
}

Future storeFrameBaseDisplayPreference(int base) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.setInt(frameBasePreferenceKey, base);
}
