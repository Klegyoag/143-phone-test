import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/features/us/presentation/modules/game_play_screen.dart';

void main() {
  test('all supported game keys produce playable prompts', () {
    const keys = [
      'how-well-do-you-know-me', 'this-or-that', 'would-you-rather',
      'who-is-more-likely', 'guess-my-answer', 'couple-trivia', 'memory-quiz',
      'finish-my-sentence', 'relationship-bingo', 'rapid-fire', 'emoji-guess',
      'two-truths-and-a-lie', 'compatibility-challenge',
    ];
    for (final key in keys) {
      expect(CoupleGameBank.forKey(key), isNotEmpty, reason: key);
      expect(CoupleGameBank.forKey(key).every((q) => q.key.isNotEmpty && q.question.isNotEmpty), isTrue, reason: key);
    }
  });
}
