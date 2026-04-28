import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

mixin SnackbarShower<T extends StatefulWidget> on State<T> {
  static const IconData emptyIcon = Icons.check_box_outline_blank;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData okIcon = Icons.check;
  static const IconData deleteIcon = Icons.delete;
  static const IconData undoIcon = Icons.undo;
  static const IconData saveIcon = Icons.save_alt;
  static const IconData copyIcon = Icons.copy;
  static const IconData canceledIcon = Icons.cancel;

  void showSnackBar(SnackBar snackbar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(snackbar);
  }

  Widget _snackbarThemes({required Widget child}) {
    return IconTheme(
      data: IconThemeData(
        color: Theme.of(context).colorScheme.onInverseSurface,
      ),
      child: child,
    );
  }

  Widget _iconThenLabel({required String label, Icon? icon}) {
    return Row(
      children: [
        if (icon != null)
          Padding(padding: const EdgeInsets.only(right: 10), child: icon),
        Flexible(child: Text(label)),
      ],
    );
  }

  void showSnackBarMessage({
    required String label,
    Icon? icon,
    SnackBarAction? action,
  }) {
    showSnackBar(
      SnackBar(
        content: _snackbarThemes(
          child: _iconThenLabel(
            label: label,
            icon: icon,
          ),
        ),
        action: action,
      ),
    );
  }

  void showProgressSnackBar({
    Icon? icon,
    required String label,
    required ValueListenable<double> progressListenable,
    SnackBarAction? action,
  }) {
    showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        action: action,
        content: _snackbarThemes(
          child: Column(
            children: [
              _iconThenLabel(
                label: label,
                icon: icon,
              ),
              ValueListenableBuilder(
                valueListenable: progressListenable,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    value: value,
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
