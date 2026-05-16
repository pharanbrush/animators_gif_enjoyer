import 'dart:io';

import 'package:animators_gif_enjoyer/phlutter/widget/preferences_stored_bool.dart';
import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:path/path.dart' as p;
import 'package:undo/undo.dart';

import '../main_screen/menu_items.dart';
import '../phlutter/phmaterial/frame_slider.dart';
import '../phlutter/simple_notifier.dart';

mixin FrameMarker {
  final frameMarkersChanged = SimpleNotifier();
  final frameMarkers = <int>{};
  final snapMode = ValueNotifier(SnapMode.nearest);
  final markersUnsaved = ValueNotifier(false);
  final askToSaveFrameMarkers = PreferencesStoredBool(
    preferenceKey: "ask to save frame markers",
    defaultValue: false,
  );

  bool get allowEditMarker;

  void doChange(Change change);

  void addMarker(int frameNumber) {
    if (!allowEditMarker) return;
    if (frameMarkers.contains(frameNumber)) return;

    doChange(
      Change<int>(
        frameNumber,
        () => _doAddMarker(frameNumber),
        (oldValue) => _doRemoveMarker(oldValue),
      ),
    );
  }

  void removeMarker(int frameNumber) {
    if (!allowEditMarker) return;
    if (!frameMarkers.contains(frameNumber)) return;

    doChange(
      Change<int>(
        frameNumber,
        () => _doRemoveMarker(frameNumber),
        (oldValue) => _doAddMarker(oldValue),
      ),
    );

    frameMarkers.remove(frameNumber);
    frameMarkersChanged.notify();
  }

  void toggleMarkerForFrame(int frameNumber) {
    if (hasMarker(frameNumber)) {
      removeMarker(frameNumber);
    } else {
      addMarker(frameNumber);
    }
  }

  bool hasMarker(int frameNumber) {
    return frameMarkers.contains(frameNumber);
  }

  void userClearMarkers() {
    if (!allowEditMarker) return;
    if (frameMarkers.isEmpty) return;
    markersUnsaved.value = true;

    doChange(
      Change<Iterable<int>>(
        [...frameMarkers], // copy
        () => _doClearMarkers(),
        (oldValue) => _doSetMarkers(oldValue),
      ),
    );
  }

  void clearMarkersInternal() {
    if (frameMarkers.isEmpty) return;
    _doClearMarkers();
  }

  void _doAddMarker(int frameNumber) {
    frameMarkers.add(frameNumber);
    markersUnsaved.value = true;
    frameMarkersChanged.notify();
  }

  void _doRemoveMarker(int frameNumber) {
    frameMarkers.remove(frameNumber);
    markersUnsaved.value = true;
    frameMarkersChanged.notify();
  }

  void _doSetMarkers(Iterable<int> markers) {
    frameMarkers.addAll(markers);
    frameMarkersChanged.notify();
  }

  void _doClearMarkers() {
    frameMarkers.clear();
    frameMarkersChanged.notify();
  }

  MenuItem addAskToSaveFrameMarkers(Menu menu) {
    return addMenuItemCheckbox(
      label: "Ask to save frame markers",
      menu: menu,
      checked: askToSaveFrameMarkers.value,
      onClick: askToSaveFrameMarkers.toggle,
    );
  }
}

// Menus

// File Operations

Future<String?> getMarkerFilePathForPath(String path) async {
  final type = await FileSystemEntity.type(path);
  return switch (type) {
    .directory => _getMarkerFilePathForFolder(path),
    .file => _getMarkerFilePathForFile(path),
    _ => null,
  };
}

String _getMarkerFilePathForFile(String imagePath) {
  return "${p.dirname(imagePath)}"
      "${p.separator}"
      "${p.basenameWithoutExtension(imagePath)}"
      ".markers.txt";
}

String _getMarkerFilePathForFolder(String folderPath) {
  return "$folderPath"
      "${p.separator}"
      "markers.txt";
}

Future<File?> saveMarkers(
  Iterable<int> markers, {
  required String outputFilePath,
  Future<bool> Function()? onAskOverwrite,
}) async {
  var file = File(outputFilePath);
  final fileExists = await file.exists();
  if (onAskOverwrite != null && fileExists) {
    final overwrite = await onAskOverwrite();
    if (!overwrite) return null;
  }

  if (!fileExists) {
    file = await file.create();
  }

  final sortedMarkers = <int>[...markers];
  sortedMarkers.sort();

  final fileContents = sortedMarkers.join("\n");

  await file.writeAsString(fileContents, flush: true);

  debugPrint("[frame_marker] Markers saved. ${file.path}");

  return file;
}

Future<Iterable<int>?> loadMarkers(String markerFilePath) async {
  final file = File(markerFilePath);
  final exists = await file.exists();
  if (!exists) return null;

  final lines = await file.readAsLines();

  final markers = <int>[];
  for (final line in lines) {
    final value = int.tryParse(line);
    if (value == null) continue;
    if (value < 0) continue;

    markers.add(value);
  }

  return markers;
}
