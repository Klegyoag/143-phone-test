import 'dart:async';
import 'dart:typed_data';

import '../../../core/api/api_client.dart';

class UploadedMedia {
  const UploadedMedia({required this.id, required this.mime, required this.size, required this.storageKey});
  final String id, mime, storageKey;
  final int size;

  factory UploadedMedia.fromJson(Map<String, dynamic> json) => UploadedMedia(
        id: '${json['id'] ?? ''}',
        mime: '${json['mime'] ?? 'application/octet-stream'}',
        size: int.tryParse('${json['size'] ?? 0}') ?? 0,
        storageKey: '${json['storage_key'] ?? ''}',
      );
}

class MediaRepository {
  MediaRepository(this._api);
  final ApiClient _api;

  Future<UploadedMedia> upload({
    required String filename,
    required String mime,
    required Uint8List bytes,
    Map<String, dynamic> metadata = const {},
    void Function(double progress)? onProgress,
    int maxAttempts = 3,
  }) async {
    final presignResponse = await _api.post('/uploads/presign', data: {
      'filename': filename,
      'mime': mime,
      'size': bytes.length,
    });
    final presign = (presignResponse['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final key = '${presign['key'] ?? ''}';
    final url = presign['url']?.toString();

    if (key.isEmpty) throw StateError('The server did not return an upload object key.');
    if (url == null || url.isEmpty) {
      throw StateError('${presign['note'] ?? 'Direct upload URL is unavailable. Check the R2/S3 upload configuration.'}');
    }

    final headers = (presign['headers'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _api.putSignedBytes(
          url,
          bytes,
          mime: mime,
          headers: headers,
          onSendProgress: (sent, total) {
            if (total > 0) onProgress?.call((sent / total).clamp(0.0, 1.0).toDouble());
          },
        );
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
        if (attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 350 * (1 << (attempt - 1))));
      }
    }
    if (lastError != null) throw lastError;
    onProgress?.call(1);

    final completeResponse = await _api.post('/uploads/complete', data: {
      'key': key,
      'mime': mime,
      'size': bytes.length,
      'metadata': metadata,
    });
    final media = (completeResponse['data'] as Map?)?.cast<String, dynamic>() ?? {};
    return UploadedMedia.fromJson(media);
  }

  Future<String?> temporaryUrl(String mediaId) async {
    final response = await _api.get('/media/$mediaId');
    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? {};
    return data['url']?.toString();
  }
}
