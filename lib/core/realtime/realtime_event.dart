class RealtimeEvent {
  const RealtimeEvent({required this.name, required this.channel, required this.payload});

  final String name;
  final String channel;
  final Map<String, dynamic> payload;

  bool get isInternal => name.startsWith('pusher:') || name.startsWith('pusher_internal:');
}
