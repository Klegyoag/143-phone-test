import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/realtime/realtime_events.dart';

void main() {
  test('chat events match Laravel realtime catalog', () {
    expect(RealtimeEvents.chatMessageCreated, 'chat.message.created');
    expect(RealtimeEvents.chatMessageUpdated, 'chat.message.updated');
    expect(RealtimeEvents.chatMessageDeleted, 'chat.message.deleted');
    expect(RealtimeEvents.chatMessageReactionUpdated, 'chat.message.reaction.updated');
    expect(RealtimeEvents.chatMessageRead, 'chat.message.read');
  });
}
