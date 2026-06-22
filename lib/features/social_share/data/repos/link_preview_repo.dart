import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/social_share/data/models/link_preview.dart';

class LinkPreviewRepo {
  final Dio _dio;
  // Simple in-memory cache: url → preview
  final Map<String, LinkPreview> _cache = {};

  LinkPreviewRepo(this._dio);

  Future<LinkPreview?> fetchPreview(String url) async {
    if (_cache.containsKey(url)) return _cache[url];
    try {
      final res = await _dio.get(ApiConstants.linkPreview(url));
      if (res.statusCode == 200 && res.data is Map) {
        final preview = LinkPreview.fromJson(res.data as Map<String, dynamic>);
        _cache[url] = preview;
        return preview;
      }
    } catch (_) {
      // Silently fail — link previews are optional UI enrichment
    }
    return null;
  }
}
