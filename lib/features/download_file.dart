bool isUrlString(String? text) {
  if (text == null || text.isEmpty) return false;

  try {
    var uri = Uri.parse(text);
    if (uri.host.isEmpty) return false;

    return true;
  } catch (e) {
    return false;
  }
}
