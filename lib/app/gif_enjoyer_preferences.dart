import 'package:flutter/widgets.dart';

import '../phlutter/widget/preferences_stored_bool.dart';

mixin GifEnjoyerWindowPreferences<T extends StatefulWidget> on State<T> {
  final allowWideSliderPreference = PreferencesStoredBool(
    preferenceKey: "allow_wide_slider",
    defaultValue: false,
    onLog: debugPrint,
  );
  final allowSliderWrapAroundDragPreference = PreferencesStoredBool(
    preferenceKey: "allow_wrap_slider",
    defaultValue: true,
    onLog: debugPrint,
  );

  late final allPreferences = [
    allowWideSliderPreference,
    allowSliderWrapAroundDragPreference,
  ];

  @override
  void initState() {
    super.initState();
    initializePreferences();
  }

  Future<void> initializePreferences() async {
    for (final preference in allPreferences) {
      await preference.loadFromPreferences();
    }
  }
}
