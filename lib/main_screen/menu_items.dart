import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/main_screen/gif_enjoyer_preferences.dart'
    as gif_enjoyer_preferences;
import 'package:animators_gif_enjoyer/phlutter/remember_window_size.dart'
    as remember_window_size;
import 'package:animators_gif_enjoyer/phlutter/single_instance.dart'
    as single_instance;
import 'package:contextual_menu/contextual_menu.dart';
import 'package:animators_gif_enjoyer/functionality/reveal_file_source.dart'
    as reveal_file_source;
import 'package:animators_gif_enjoyer/utils/build_info.dart' as build_info;
import 'package:flutter/material.dart';

const String openImageSequenceFolderLabel = 'Open image sequence folder...';
const String advancedLabel = 'Advanced';
const String exportPngSequenceLabel = 'Export PNG Sequence...';
const String pasteToAddressBarLabel = 'Paste to address bar...';
const String openGifLabel = 'Open GIF...';
const String copyFrameImageLabel = 'Copy frame image';

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

MenuItem allowWideSliderMenuItem(ValueNotifier<bool> allowWideSliderNotifier) {
  return MenuItem.checkbox(
    label: 'Allow wide frame slider',
    checked: allowWideSliderNotifier.value,
    key: 'allowWideSlider',
    onClick: (menuItem) async {
      gif_enjoyer_preferences
          .toggleAllowWideSliderPreference(allowWideSliderNotifier);
    },
  );
}

MenuItem rememberWindowSizeMenuItem() {
  return MenuItem.checkbox(
    label: 'Remember window size',
    checked: appRememberSize,
    key: 'appRememberSize',
    onClick: (menuItem) async {
      remember_window_size.storeRememberWindowSizePreference(!appRememberSize);
      appRememberSize =
          await remember_window_size.getRememberWindowSizePreference();

      if (appRememberSize) {
        remember_window_size.storeCurrentWindowSize();
      }
    },
  );
}

MenuItem revealMenuItem(
  ImageProvider? imageProvider, {
  String? source,
}) {
  switch (imageProvider) {
    case FileImage fi:
      return MenuItem(
        label: 'Reveal in File Explorer',
        onClick: (_) => reveal_file_source.revealInExplorer(fi.file.path),
      );
    case NetworkImage ni:
      return MenuItem(
        label: 'Open original link in browser',
        onClick: (_) => reveal_file_source.openInBrowser(ni.url),
      );
    default:
      if (source != null && source.isNotEmpty) {
        return MenuItem(
          label: 'Reveal in File Explorer',
          onClick: (_) => reveal_file_source.revealInExplorer(source),
        );
      }

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
