import 'package:flutter/material.dart';

WidgetStateProperty<Color> hoverColors({
  required Color idle,
  required Color hover,
}) {
  return WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.hovered) ? hover : idle);
}

WidgetStateProperty<T> hoverProperty<T>({
  required T idle,
  required T hover,
}) {
  return WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.hovered) ? hover : idle);
}

WidgetStateProperty<T> hoverActiveDisabledProperty<T>({
  required T idle,
  required T hover,
  required T active,
  required T disabled,
}) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.hovered)) {
      return hover;
    } else if (states.contains(WidgetState.selected)) {
      return active;
    } else if (states.contains(WidgetState.disabled)) {
      return disabled;
    }

    return idle;
  });
}

WidgetStateProperty<Color> hoverActiveColors({
  required Color idle,
  required Color hover,
  required Color active,
}) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.hovered)) {
      return hover;
    } else if (states.contains(WidgetState.selected)) {
      return active;
    }

    return idle;
  });
}
