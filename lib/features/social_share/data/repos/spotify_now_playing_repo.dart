import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/social_share/data/models/spotify_now_playing.dart';
import 'package:riff/features/social_share/services/spotify_auth_service.dart';

/// Fetches the currently playing track from the Spotify Web API.
class SpotifyNowPlayingRepo {
  static const _spotifyEndpoint =
      'https://api.spotify.com/v1/me/player/currently-playing';

  /// Fetch the CURRENT user's now-playing directly from Spotify.
  /// Returns null if not connected, nothing playing, or an error occurred.
  Future<SpotifyNowPlaying?> fetch() async {
    final token = await SpotifyAuthService.instance.getAccessToken();
    if (token == null) return null;

    try {
      final res = await http.get(
        Uri.parse(_spotifyEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 204 || res.body.isEmpty) return null;
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return SpotifyNowPlaying.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Fetch ANOTHER user's now-playing via the Riff backend.
  /// The backend uses that user's stored Spotify token to call the Spotify API.
  /// Returns null if the user hasn't connected Spotify or nothing is playing.
  Future<SpotifyNowPlaying?> fetchForUser(String userId) async {
    final jwt = await SharedPrefHelper.getString(SharedPrefKeys.userToken) as String? ?? '';
    if (jwt.isEmpty) return null;

    try {
      final url = Uri.parse(
        '${ApiConstants.apiBASEURL}${ApiConstants.spotifyNowPlayingForUser(userId)}',
      );
      final res = await http.get(url, headers: {'Authorization': 'Bearer $jwt'});

      if (res.statusCode == 204 || res.body.isEmpty) return null;
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return SpotifyNowPlaying.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
