import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/main_screen/gif_enjoyer_preferences.dart'
    as gif_enjoyer_preferences;
import 'package:animators_gif_enjoyer/phlutter/pheatures/remember_window_size.dart'
    as remember_window_size;
import 'package:animators_gif_enjoyer/functionality/single_instance.dart'
    as single_instance;
import 'package:animators_gif_enjoyer/functionality/reveal_file_source.dart'
    as reveal_file_source;
import 'package:animators_gif_enjoyer/phlutter/dart/build_info.dart'
    as build_info;
import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

const String openImageSequenceFolderLabel = 'Open image sequence folder...';
const String advancedLabel = 'Advanced';
const String exportPngSequenceLabel = 'Export PNG Sequence...';
const String pasteToAddressBarLabel = 'Paste to address bar...';
const String openGifLabel = 'Open GIF...';
const String copyFrameImageLabel = 'Copy frame image';

MenuItem menuItem({
  required String label,
  required Menu menu,
  VoidCallback? onClick,
  MenuItemType type = MenuItemType.normal,
}) {
  final item = MenuItem(label, type);
  menu.addItem(item);

  if (onClick != null) {
    item.on<MenuItemClickedEvent>((_) => onClick());
  }
  return item;
}

MenuItem menuItemCheckbox({
  required String label,
  required Menu menu,
  required bool checked,
  VoidCallback? onClick,
}) {
  final item = menuItem(
    label: label,
    menu: menu,
    onClick: onClick,
    type: .checkbox,
  );
  item.state = checked ? .checked : .unchecked;
  return item;
}

MenuItem allowMultipleWindowsMenuItem(Menu menu) {
  return menuItemCheckbox(
    label: "Allow multiple windows",
    menu: menu,
    checked: appAllowMultipleInstances,
    onClick: () async {
      single_instance.storeAllowMultipleInstancePreference(
        !appAllowMultipleInstances,
      );
      appAllowMultipleInstances = await single_instance
          .getAllowMultipleInstancePreference();
    },
  );
}

MenuItem allowWideSliderMenuItem(
  ValueNotifier<bool> allowWideSliderNotifier,
  Menu menu,
) {
  return menuItemCheckbox(
    label: "Allow wide frame slider",
    menu: menu,
    checked: allowWideSliderNotifier.value,
    onClick: () => gif_enjoyer_preferences.toggleAllowWideSliderPreference(
      allowWideSliderNotifier,
    ),
  );
}

MenuItem rememberWindowSizeMenuItem(Menu menu) {
  return menuItemCheckbox(
    label: "Remember window size",
    menu: menu,
    checked: remember_window_size.appRememberWindowSize,
    onClick: () async {
      remember_window_size.storeRememberWindowSizePreference(
        !remember_window_size.appRememberWindowSize,
      );
      remember_window_size.appRememberWindowSize = await remember_window_size
          .getRememberWindowSizePreference();

      if (remember_window_size.appRememberWindowSize) {
        remember_window_size.storeCurrentWindowSize();
      }
    },
  );
}

MenuItem revealMenuItem(
  ImageProvider? imageProvider, {
  String? source,
  required Menu menu,
}) {
  switch (imageProvider) {
    case FileImage fi:
      return menuItem(
        label: "Reveal in File Explorer",
        menu: menu,
        onClick: () => reveal_file_source.revealInExplorer(fi.file.path),
      );
    case NetworkImage ni:
      return menuItem(
        menu: menu,
        label: "Open original link in browser",
        onClick: () => reveal_file_source.openInBrowser(ni.url),
      );
    default:
      if (source != null && source.isNotEmpty) {
        return menuItem(
          menu: menu,
          label: "Reveal in File Explorer",
          onClick: () => reveal_file_source.revealInExplorer(source),
        );
      }

      return menuItem(label: "Reveal in Explorer", menu: menu, onClick: () {})
        ..enabled = false;
  }
}

void addAboutItemsTo(Menu menu) {
  menu.addSeparator();
  menuItem(label: "Build ${build_info.buildName}", menu: menu).enabled = false;
}

extension MenuExtensions on Menu {
  void addItems(Iterable<MenuItem> items) {
    for (final item in items) {
      addItem(item);
    }
  }
}
