import 'dart:io';
import 'package:path/path.dart' as p;

extension NameExtensions on FileSystemEntity {
  String get basename {
    return p.basename(path);
  }
}
