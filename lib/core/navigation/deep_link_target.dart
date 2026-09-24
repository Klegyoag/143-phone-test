class DeepLinkTarget {
  const DeepLinkTarget({required this.location, this.tabIndex});
  final String location;
  final int? tabIndex;

  static DeepLinkTarget fromUri(Uri uri) {
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    final type = (uri.queryParameters['type'] ?? '').toLowerCase();

    String? inviteToken;
    if (host == 'invite' && uri.pathSegments.isNotEmpty) inviteToken = uri.pathSegments.last;
    if (path.contains('invite')) {
      final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
      final i = segments.indexWhere((e) => e.toLowerCase() == 'invite');
      if (i >= 0 && i + 1 < segments.length) inviteToken = segments[i + 1];
      inviteToken ??= uri.queryParameters['token'] ?? uri.queryParameters['code'];
    }
    if (inviteToken != null && inviteToken.isNotEmpty) {
      return DeepLinkTarget(location: '/invite/${Uri.encodeComponent(inviteToken)}');
    }

    if ((host == 'widget' && path.contains('ping')) || path.contains('widget-ping') || type == 'widget.quick_ping') {
      return const DeepLinkTarget(location: '/widget-ping', tabIndex: 0);
    }


    final callId = uri.queryParameters['call_id'];
    if ((host.contains('call') || path.contains('call') || type.contains('call')) && callId != null && callId.isNotEmpty) {
      final callType = uri.queryParameters['call_type'] ?? uri.queryParameters['media_type'] ?? 'audio';
      return DeepLinkTarget(location: '/call/${Uri.encodeComponent(callId)}?type=${Uri.encodeQueryComponent(callType)}&incoming=1', tabIndex: 3);
    }

    final memoryId = uri.queryParameters['memory_id'] ?? uri.queryParameters['id'];
    if ((host.contains('memory') || path.contains('memory') || type.contains('memory') || type.contains('capsule')) && memoryId != null && memoryId.isNotEmpty) {
      return DeepLinkTarget(location: '/memory/${Uri.encodeComponent(memoryId)}', tabIndex: 1);
    }
    if (host.contains('chat') || path.contains('chat') || type.contains('chat') || type.contains('message')) {
      return const DeepLinkTarget(location: '/app?tab=3', tabIndex: 3);
    }
    if (host.contains('memory') || path.contains('memory') || type.contains('memory') || type.contains('capsule')) {
      return const DeepLinkTarget(location: '/app?tab=1', tabIndex: 1);
    }
    if (path.contains('couple') || type.contains('couple')) {
      return const DeepLinkTarget(location: '/couple-setup');
    }
    if (path.contains('notification')) {
      return const DeepLinkTarget(location: '/app?tab=0', tabIndex: 0);
    }
    if (path.contains('calendar') || path.contains('goal') || path.contains('journey') || path.contains('together') || type.contains('calendar') || type.contains('goal') || type.contains('journey') || type.contains('together')) {
      return const DeepLinkTarget(location: '/app?tab=4', tabIndex: 4);
    }
    if (type.contains('call')) return const DeepLinkTarget(location: '/app?tab=3', tabIndex: 3);
    return const DeepLinkTarget(location: '/app?tab=0', tabIndex: 0);
  }

  static DeepLinkTarget fromPayload(Map<String, dynamic> payload) {
    final raw = payload['deep_link'] ?? payload['url'] ?? payload['link'];
    if (raw != null) {
      final uri = Uri.tryParse('$raw');
      if (uri != null) return fromUri(uri);
    }
    final nested = payload['action_data'] ?? payload['data'] ?? payload['metadata'];
    final merged = <String, dynamic>{...payload};
    if (nested is Map) merged.addAll(nested.cast<String, dynamic>());
    final type = '${merged['type'] ?? merged['event'] ?? ''}';
    final query = <String, String>{'type': type};
    for (final key in ['memory_id','message_id','conversation_id','call_id','call_type','media_type','event_id','goal_id','journey_id','id']) {
      final value = merged[key]; if (value != null) query[key] = '$value';
    }
    return fromUri(Uri(path: '/', queryParameters: query));
  }
}
