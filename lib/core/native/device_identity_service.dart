import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentityService {
  static const _key = 'device_identity_v1';

  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    return id;
  }

  String get platform => Platform.isIOS ? 'ios' : 'android';
  String get defaultName => Platform.isIOS ? 'iPhone / iPad' : 'Android device';
}
