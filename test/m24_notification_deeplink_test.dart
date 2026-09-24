import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/navigation/deep_link_target.dart';

void main() {
  test('native push memory payload keeps memory context', () {
    final target = DeepLinkTarget.fromPayload({
      'type': 'memory.reaction',
      'memory_id': 'memory-143',
    });
    expect(target.location, '/memory/memory-143');
    expect(target.tabIndex, 1);
  });

  test('incoming call payload opens the exact call session', () {
    final target = DeepLinkTarget.fromPayload({
      'type': 'call.incoming',
      'call_id': 'call-143',
      'call_type': 'video',
    });
    expect(target.location, contains('/call/call-143'));
    expect(target.location, contains('type=video'));
    expect(target.tabIndex, 3);
  });

  test('chat notification opens Chat tab', () {
    final target = DeepLinkTarget.fromPayload({
      'type': 'chat.message.created',
      'conversation_id': 'conversation-143',
    });
    expect(target.location, '/app?tab=3');
    expect(target.tabIndex, 3);
  });
}
