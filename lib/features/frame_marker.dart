import 'package:flutter/material.dart';

import '../phlutter/phmaterial/frame_slider.dart';
import '../phlutter/simple_notifier.dart';

mixin FrameMarker {
  final frameMarkersChanged = SimpleNotifier();
  final frameMarkers = <int>{};
  final snapMode = ValueNotifier(SnapMode.nearest);

  void addMarker(int frameNumber) {
    final changed = frameMarkers.add(frameNumber);
    if (changed) {
      frameMarkersChanged.notify();
      // print("marker added $frameNumber");
    }
  }

  void removeMarker(int frameNumber) {
    final changed = frameMarkers.remove(frameNumber);
    if (changed) {
      frameMarkersChanged.notify();
      // print("marker removed $frameNumber");
    }
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

  void clearMarkers() {
    if (frameMarkers.isEmpty) return;
    frameMarkers.clear();
    frameMarkersChanged.notify();
  }
}
