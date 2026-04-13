import 'package:flutter/foundation.dart';

/// [SimpleNotifier] is a subclass of ChangeNotifier that just exposes a [notify] method so it can be controlled outside of the class.
class SimpleNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
