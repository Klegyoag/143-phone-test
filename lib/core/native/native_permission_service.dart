import 'package:permission_handler/permission_handler.dart';

/// Central native-permission boundary.
///
/// Server-side consent and OS-level permission are intentionally separate:
/// the backend records what the user consents to, while this class requests the
/// Android/iOS capability only when the user enters a feature that needs it.
class NativePermissionService {
  Future<PermissionStatus> requestCamera() => Permission.camera.request();
  Future<PermissionStatus> requestMicrophone() => Permission.microphone.request();
  Future<PermissionStatus> requestPhotos() => Permission.photos.request();
  Future<PermissionStatus> requestLocationWhenInUse() => Permission.locationWhenInUse.request();
  Future<PermissionStatus> requestNotifications() => Permission.notification.request();

  Future<Map<String, PermissionStatus>> currentStatuses() async => {
        'camera': await Permission.camera.status,
        'microphone': await Permission.microphone.status,
        'photos': await Permission.photos.status,
        'location': await Permission.locationWhenInUse.status,
        'notifications': await Permission.notification.status,
      };

  Future<bool> openSettings() => openAppSettings();
}
