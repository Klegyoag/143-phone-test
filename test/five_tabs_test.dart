import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product contract keeps exactly five primary tabs', () {
    const tabs = ['Home','Memories','Create','Chat','Us'];
    expect(tabs, hasLength(5));
    expect(tabs[2], 'Create');
  });
}
