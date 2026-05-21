import 'dart:async';

import 'package:app_links/app_links.dart';

class DeepLinkService {
  DeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  /// Listens for universal links and custom URL schemes.
  void listen(void Function(Uri uri) onLink) {
    _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(onLink);
  }

  Future<Uri?> getInitialLink() async {
    return _appLinks.getInitialLink();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
