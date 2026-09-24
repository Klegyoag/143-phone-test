import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

import 'deep_link_target.dart';

class NativeDeepLinkCoordinator {
  NativeDeepLinkCoordinator(this._router);
  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> start() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _route(initial);
    _sub = _appLinks.uriLinkStream.listen(_route);
  }

  void _route(Uri uri) {
    final target = DeepLinkTarget.fromUri(uri);
    _router.go(target.location);
  }

  Future<void> dispose() async => _sub?.cancel();
}
