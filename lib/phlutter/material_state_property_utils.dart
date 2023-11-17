import 'package:flutter/material.dart';

MaterialStateProperty<Color> hoverColors({
  required Color idle,
  required Color hover,
}) {
  return MaterialStateProperty.resolveWith(
      (states) => states.contains(MaterialState.hovered) ? hover : idle);
}

MaterialStateProperty<T> hoverProperty<T>({
  required T idle,
  required T hover,
}) {
  return MaterialStateProperty.resolveWith(
      (states) => states.contains(MaterialState.hovered) ? hover : idle);
}

MaterialStateProperty<T> hoverActiveDisabledProperty<T>({
  required T idle,
  required T hover,
  required T active,
  required T disabled,
}) {
  return MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.hovered)) {
      return hover;
    } else if (states.contains(MaterialState.selected)) {
      return active;
    } else if (states.contains(MaterialState.disabled)) {
      return disabled;
    }

    return idle;
  });
}

MaterialStateProperty<Color> hoverActiveColors({
  required Color idle,
  required Color hover,
  required Color active,
}) {
  return MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.hovered)) {
      return hover;
    } else if (states.contains(MaterialState.selected)) {
      return active;
    }

    return idle;
  });
}
