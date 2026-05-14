import 'package:flutter/material.dart';
import 'package:undo/undo.dart';

import '../phlutter/phmaterial/frame_slider.dart';
import '../phlutter/simple_notifier.dart';

mixin FrameMarker {
  final frameMarkersChanged = SimpleNotifier();
  final frameMarkers = <int>{};
  final snapMode = ValueNotifier(SnapMode.nearest);

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

  void clearMarkers({bool undoable = false}) {
    if (!allowEditMarker) return;
    if (frameMarkers.isEmpty) return;

    if (undoable) {
      doChange(
        Change<Iterable<int>>(
          [...frameMarkers], // copy
          () => _doClearMarkers(),
          (oldValue) => _doSetMarkers(oldValue),
        ),
      );
    } else {
      _doClearMarkers();
    }
  }

  void _doAddMarker(int frameNumber) {
    frameMarkers.add(frameNumber);
    frameMarkersChanged.notify();
  }

  void _doRemoveMarker(int frameNumber) {
    frameMarkers.remove(frameNumber);
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
}
