import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/navigation/deep_link_target.dart';

void main() {
  test('invite deep link retains token', () {
    final target = DeepLinkTarget.fromUri(Uri.parse('143://invite/ABC123'));
    expect(target.location, '/invite/ABC123');
  });
  test('memory notification can open a concrete memory', () {
    final target = DeepLinkTarget.fromPayload({'type':'memory.updated','memory_id':'m-1'});
    expect(target.location, '/memory/m-1');
  });
  test('private memory custom-scheme link opens a concrete memory', () {
    final target = DeepLinkTarget.fromUri(Uri.parse('143://memory?memory_id=m-2'));
    expect(target.location, '/memory/m-2');
  });
  test('chat deep link keeps Chat as fixed tab 3', () {
    final target = DeepLinkTarget.fromUri(Uri.parse('143://chat'));
    expect(target.tabIndex, 3);
  });
}
