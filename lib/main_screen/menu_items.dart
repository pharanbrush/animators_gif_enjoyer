import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

import '../features/reveal_file_source.dart' as reveal_file_source;
import '../features/single_instance.dart' as single_instance;
import '../main.dart';
import '../phlutter/phdart/build_info.dart' as build_info;
import '../phlutter/pheatures/remember_window_size.dart'
    as remember_window_size;
import '../phlutter/widget/preferences_stored_bool.dart';

const String openImageSequenceFolderLabel = 'Open image sequence folder...';
const String advancedLabel = 'Advanced';
const String exportPngSequenceLabel = 'Export PNG Sequence...';
const String pasteToAddressBarLabel = 'Paste to address bar...';
const String openGifLabel = 'Open GIF...';
const String copyFrameImageLabel = 'Copy frame image';

MenuItem addMenuItem({
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

MenuItem addMenuItemCheckbox({
  required String label,
  required Menu menu,
  required bool checked,
  VoidCallback? onClick,
}) {
  final item = addMenuItem(
    label: label,
    menu: menu,
    onClick: onClick,
    type: .checkbox,
  );
  item.state = checked ? .checked : .unchecked;
  return item;
}

MenuItem addAllowMultipleWindowsMenuItem(Menu menu) {
  return addMenuItemCheckbox(
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

MenuItem addAllowWideSliderMenuItem(
  PreferencesStoredBool allowWideSliderPreference,
  Menu menu,
) {
  return addMenuItemCheckbox(
    label: "Allow wide frame slider",
    menu: menu,
    checked: allowWideSliderPreference.value,
    onClick: () => allowWideSliderPreference.toggle(),
  );
}

MenuItem addAllowSliderWrapMenuItem(
  PreferencesStoredBool allowWrapDragPreference,
  Menu menu,
) {
  return addMenuItemCheckbox(
    label: "Loop when dragging slider",
    menu: menu,
    checked: allowWrapDragPreference.value,
    onClick: () => allowWrapDragPreference.toggle(),
  );
}

MenuItem addRememberWindowSizeMenuItem(Menu menu) {
  return addMenuItemCheckbox(
    label: "Remember window size",
    menu: menu,
    checked: remember_window_size.appRememberWindowSize.value,
    onClick: () => remember_window_size.appRememberWindowSize.toggle(),
  );
}

MenuItem addRevealMenuItem(
  ImageProvider? imageProvider, {
  String? source,
  required Menu menu,
}) {
  switch (imageProvider) {
    case FileImage fi:
      return addMenuItem(
        label: "Reveal in File Explorer",
        menu: menu,
        onClick: () => reveal_file_source.revealInExplorer(fi.file.path),
      );
    case NetworkImage ni:
      return addMenuItem(
        menu: menu,
        label: "Open original link in browser",
        onClick: () => reveal_file_source.openInBrowser(ni.url),
      );
    default:
      if (source != null && source.isNotEmpty) {
        return addMenuItem(
          menu: menu,
          label: "Reveal in File Explorer",
          onClick: () => reveal_file_source.revealInExplorer(source),
        );
      }

      return addMenuItem(
        label: "Reveal in Explorer",
        menu: menu,
        onClick: () {},
      )..enabled = false;
  }
}

void tryAddAboutItemsTo(Menu menu) {
  if (build_info.packageInfo != null) return;

  menu.addSeparator();
  addMenuItem(label: "Build ${build_info.buildName}", menu: menu).enabled =
      false;
}

extension MenuExtensions on Menu {
  void addItems(Iterable<MenuItem> items) {
    for (final item in items) {
      addItem(item);
    }
  }
}
