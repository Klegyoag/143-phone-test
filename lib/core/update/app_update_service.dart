import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.installedVersion,
    this.latestVersion,
    this.minimumVersion,
    this.storeUrl,
    this.releaseNotes,
    this.required = false,
    this.available = false,
    this.configured = false,
  });

  final String installedVersion;
  final String? latestVersion;
  final String? minimumVersion;
  final String? storeUrl;
  final String? releaseNotes;
  final bool required;
  final bool available;
  final bool configured;
}

/// Version-check boundary for feature 257.
///
/// 143 deliberately does not invent a Laravel endpoint. Release builds may
/// provide a public HTTPS manifest URL using --dart-define=APP_UPDATE_MANIFEST_URL=...
/// The manifest may contain latest_version, minimum_version, store_url and
/// release_notes. No secret belongs in this manifest or in Flutter source.
class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  static const manifestUrl = String.fromEnvironment('APP_UPDATE_MANIFEST_URL');

  Future<AppUpdateInfo> check() async {
    final package = await PackageInfo.fromPlatform();
    final installed = package.version;
    if (manifestUrl.isEmpty) {
      return AppUpdateInfo(installedVersion: installed);
    }
    final uri = Uri.tryParse(manifestUrl);
    if (uri == null || uri.scheme != 'https') {
      throw StateError('APP_UPDATE_MANIFEST_URL must be an HTTPS URL.');
    }
    final response = await _dio.getUri(uri, options: Options(responseType: ResponseType.json));
    final raw = response.data;
    if (raw is! Map) throw const FormatException('Update manifest must be a JSON object.');
    final data = Map<String, dynamic>.from(raw);
    final latest = data['latest_version']?.toString();
    final minimum = data['minimum_version']?.toString();
    return AppUpdateInfo(
      installedVersion: installed,
      latestVersion: latest,
      minimumVersion: minimum,
      storeUrl: data['store_url']?.toString(),
      releaseNotes: data['release_notes']?.toString(),
      configured: true,
      available: latest != null && _compare(installed, latest) < 0,
      required: minimum != null && _compare(installed, minimum) < 0,
    );
  }

  static int _compare(String a, String b) {
    List<int> parts(String value) => value.split('+').first.split('-').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final aa = parts(a), bb = parts(b);
    final length = aa.length > bb.length ? aa.length : bb.length;
    for (var i = 0; i < length; i++) {
      final av = i < aa.length ? aa[i] : 0;
      final bv = i < bb.length ? bb[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}
