import 'package:flutter/material.dart';

extension BoolNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}
