import 'package:flutter/foundation.dart';

mixin Exporter {
  Future? inProgressExport;
  ValueNotifier<double> exportPercentProgress = ValueNotifier(0);
  ValueNotifier<bool> isExportCancelled = ValueNotifier(false);

  void updateExportPercentProgress(double percent) {
    exportPercentProgress.value = percent;
  }

  void cancelExport() {
    isExportCancelled.value = true;
  }

  void clearExportStatus() {
    inProgressExport = null;
    exportPercentProgress.value = 0;
    isExportCancelled.value = false;
  }
}
