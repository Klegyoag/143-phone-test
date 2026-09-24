import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/features/memories/data/memory_repository.dart';

void main() {
  test('memory attachment round-trips media metadata', () {
    const attachment = MemoryAttachment(
      mediaId: 'media-1',
      filename: 'photo.jpg',
      mime: 'image/jpeg',
      size: 2048,
    );
    final parsed = MemoryAttachment.fromJson(attachment.toJson());
    expect(parsed.mediaId, 'media-1');
    expect(parsed.isImage, isTrue);
    expect(parsed.filename, 'photo.jpg');
  });

  test('memory item parses tags and attachments from content', () {
    final item = MemoryItem.fromJson({
      'id': 'm1',
      'type': 'moment',
      'title': 'A day',
      'content': {
        'body': 'hello',
        'attachments': [
          {'media_id': 'x', 'filename': 'x.pdf', 'mime': 'application/pdf', 'size': 10}
        ]
      },
      'tags': ['trip', 'happy'],
      'is_locked': false,
    });
    expect(item.body, 'hello');
    expect(item.tags, ['trip', 'happy']);
    expect(item.attachments.single.isDocument, isTrue);
  });

  test('time capsule status detects future reveal', () {
    final future = DateTime.now().add(const Duration(hours: 2));
    final status = TimeCapsuleStatus.fromJson({
      'locked': true,
      'reveal_at': future.toIso8601String(),
      'revealed_at': null,
    });
    expect(status.locked, isTrue);
    expect(status.revealDue, isFalse);
  });
}
