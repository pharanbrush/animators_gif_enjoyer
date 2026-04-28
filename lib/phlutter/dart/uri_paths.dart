import 'package:path/path.dart' as p;

/// Tries to get the name of the file without the extension.
///
/// Excludes everything after the last occurence of a dot.
/// Returns an empty string if the dot comes at the start of the filename.
/// Returns the full argument if no dot was found.
/// Returns an empty string if the argument was empty or whitespace.
String? getExtensionFromUri(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.isEmpty) return null;

  final lastSegment = segments.last;
  final dotIndex = lastSegment.lastIndexOf('.');
  if (dotIndex == -1) return null;

  return lastSegment.substring(dotIndex + 1);
}

String? filenameFromUrlWithoutExtension(String url) {
  final argumentIndex = url.lastIndexOf('?');
  final lastSlashIndex = url.lastIndexOf('/');
  final filenameEndIndex = argumentIndex > lastSlashIndex
      ? argumentIndex
      : null;

  var fullFilename = url.substring(lastSlashIndex + 1, filenameEndIndex).trim();
  if (fullFilename.isEmpty) return null;

  return p.withoutExtension(fullFilename);
}
