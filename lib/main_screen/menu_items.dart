import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/phlutter/single_instance.dart'
    as single_instance;
import 'package:contextual_menu/contextual_menu.dart';
import 'package:animators_gif_enjoyer/utils/reveal_file_source.dart'
    as reveal_file_source;
import 'package:animators_gif_enjoyer/utils/build_info.dart' as build_info;
import 'package:flutter/material.dart';

MenuItem allowMultipleWindowsMenuItem() {
  return MenuItem.checkbox(
    label: 'Allow multiple windows',
    checked: appAllowMultipleInstances,
    key: 'appAllowMultipleInstances',
    onClick: (menuItem) async {
      single_instance.storeAllowMultipleInstancePreference(
        !appAllowMultipleInstances,
      );

      appAllowMultipleInstances =
          await single_instance.getAllowMultipleInstancePreference();
    },
  );
}

MenuItem revealMenuItem(ImageProvider? imageProvider) {
  switch (imageProvider) {
    case FileImage fi:
      return MenuItem(
          label: 'Reveal in File Explorer',
          onClick: (_) => reveal_file_source.revealInExplorer(fi.file.path));
    case NetworkImage ni:
      return MenuItem(
          label: 'Open original link in browser',
          onClick: (_) => reveal_file_source.openInBrowser(ni.url));
    default:
      return MenuItem(label: 'Reveal in Explorer', disabled: true);
  }
}

final aboutItem = <MenuItem>[
  MenuItem.separator(),
  MenuItem(
    label: 'Build ${build_info.buildName}',
    disabled: true,
  ),
];
