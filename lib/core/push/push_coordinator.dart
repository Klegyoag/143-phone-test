import 'dart:io' show Platform;

import '../../features/notifications/data/push_device_repository.dart';

class PushCoordinator {
  PushCoordinator(this._repository);

  final PushDeviceRepository _repository;
  String? registeredDeviceId;
  String? lastError;

  static const configuredToken = String.fromEnvironment('PUSH_DEVICE_TOKEN');
  static const configuredDeviceName = String.fromEnvironment('PUSH_DEVICE_NAME', defaultValue: 'Flutter device');

  bool get hasConfiguredToken => configuredToken.trim().isNotEmpty;

  Future<bool> registerConfiguredToken() async {
    if (!hasConfiguredToken) return false;
    try {
      final result = await _repository.register(
        token: configuredToken.trim(),
        platform: Platform.isIOS ? 'ios' : 'android',
        deviceName: configuredDeviceName,
        metadata: {
          'client': 'flutter',
          'source': 'dart-define',
        },
      );
      registeredDeviceId = '${result['id'] ?? result['device_id'] ?? ''}';
      lastError = null;
      return true;
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  Future<void> unregister() async {
    final id = registeredDeviceId;
    if (id == null || id.isEmpty) return;
    try {
      await _repository.remove(id);
    } finally {
      registeredDeviceId = null;
    }
  }
}
