import 'package:flutter/foundation.dart';

extension BoolNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}
