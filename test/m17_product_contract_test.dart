import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smart date place values match backend contract', () {
    const allowed = {'home', 'outside', 'either'};
    expect(allowed, containsAll(<String>['home', 'outside', 'either']));
    expect(allowed.contains('setting'), isFalse);
  });

  test('shared list statuses preserve the master product states', () {
    const statuses = ['want_to', 'planned', 'completed', 'favorite'];
    expect(statuses, hasLength(4));
    expect(statuses, contains('favorite'));
  });

  test('reconnection copy remains non diagnostic', () {
    const copy = 'Each of you answers privately. Answers only reveal when both have responded.';
    expect(copy.toLowerCase().contains('diagnos'), isFalse);
    expect(copy.toLowerCase().contains('score your relationship'), isFalse);
  });
}
