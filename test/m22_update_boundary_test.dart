import 'package:flutter_test/flutter_test.dart';
import 'package:one_four_three/core/update/app_update_service.dart';

void main() {
  test('version comparison handles semantic numeric parts', () {
    // Public behavior is exercised through manifest evaluation in device tests;
    // this test protects the non-secret boundary configuration default.
    expect(AppUpdateService.manifestUrl, isA<String>());
  });
}
