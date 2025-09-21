import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/music_track.dart';

class SpotifyService {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const String _accountsBaseUrl = 'https://accounts.spotify.com/api/token';

  // Your Spotify API credentials
  static const String _clientId = 'f81b3a0fb30041ebb1041f184262380a';
  static const String _clientSecret = '39ef064a6e47480989e38bf89d3364f0';

  String? _accessToken;
  DateTime? _tokenExpiry;

  // Simplified emotion-based search strategies (avoiding deprecated playlists for now)
  static const Map<String, List<String>> _emotionSearchTerms = {
    'happy': ['happy', 'upbeat', 'energetic', 'positive', 'dance', 'pop', 'feel good', 'celebration'],
    'sad': ['sad', 'melancholy', 'heartbreak', 'acoustic', 'emotional', 'slow', 'tears', 'lonely'],
    'angry': ['angry', 'aggressive', 'rock', 'metal', 'intense', 'rage', 'punk', 'hardcore'],
    'neutral': ['chill', 'ambient', 'background', 'focus', 'calm', 'peaceful', 'relaxing', 'mellow'],
    'surprised': ['experimental', 'electronic', 'unique', 'unexpected', 'jazz', 'fusion', 'weird', 'eclectic'],
    'fear': ['dark', 'atmospheric', 'ambient', 'haunting', 'mysterious', 'eerie', 'gothic', 'somber'],
    'disgust': ['industrial', 'dark', 'gothic', 'alternative', 'grunge', 'distortion', 'harsh', 'raw'],
  };

  // Get access token using Client Credentials flow
  Future<bool> _getAccessToken() async {
    try {
      if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
        return true; // Token is still valid
      }

      final credentials = base64.encode(utf8.encode('$_clientId:$_clientSecret'));

      final response = await http.post(
        Uri.parse(_accountsBaseUrl),
        headers: {'Authorization': 'Basic $credentials', 'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

        debugPrint('Spotify access token obtained successfully');
        return true;
      } else {
        debugPrint('Failed to get Spotify access token: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error getting Spotify access token: $e');
      return false;
    }
  }

  // Simplified recommendations using only search (no playlists to avoid null errors)
  Future<List<MusicTrack>> getRecommendations(String emotion, {int limit = 20}) async {
    try {
      if (!await _getAccessToken()) {
        throw Exception('Failed to authenticate with Spotify');
      }

      final searchTerms = _emotionSearchTerms[emotion.toLowerCase()] ?? _emotionSearchTerms['neutral']!;

      List<MusicTrack> allTracks = [];

      // Use multiple search terms to get variety
      for (String term in searchTerms.take(4)) {
        // Use 4 search terms
        try {
          final searchResults = await searchTracks(
            '$term year:2020-2024', // Recent music filter
            limit: limit ~/ 4, // Divide limit across searches
          );
          allTracks.addAll(searchResults);

          // Add a small delay between requests to avoid rate limiting
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('Search for "$term" failed: $e');
        }
      }

      // Remove duplicates and shuffle
      final uniqueTracks = _removeDuplicates(allTracks);
      uniqueTracks.shuffle();

      debugPrint('Loaded ${uniqueTracks.length} Spotify recommendations for $emotion emotion');
      return uniqueTracks.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      throw Exception('Error getting music recommendations: $e');
    }
  }

  // Search for tracks
  Future<List<MusicTrack>> searchTracks(String query, {int limit = 20}) async {
    try {
      if (!await _getAccessToken()) {
        throw Exception('Failed to authenticate with Spotify');
      }

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': query, 'type': 'track', 'limit': limit.toString(), 'market': 'US'});

      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_accessToken', 'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']?['items'] as List? ?? [];

        return tracks.where((track) => track != null).map((track) => _mapSpotifyTrackToMusicTrack(track)).toList();
      } else {
        debugPrint('Failed to search tracks: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception('Failed to search tracks');
      }
    } catch (e) {
      debugPrint('Error searching tracks: $e');
      throw Exception('Error searching tracks: $e');
    }
  }

  // Get featured playlists with better null safety
  Future<List<Map<String, dynamic>>> getFeaturedPlaylists({int limit = 10}) async {
    try {
      if (!await _getAccessToken()) {
        throw Exception('Failed to authenticate with Spotify');
      }

      final uri = Uri.parse('$_baseUrl/browse/featured-playlists').replace(queryParameters: {'limit': limit.toString(), 'country': 'US'});

      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_accessToken', 'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlists = data['playlists']?['items'] as List? ?? [];

        return playlists
            .where((playlist) => playlist != null && playlist['id'] != null)
            .map(
              (playlist) => {
                'id': playlist['id'] ?? '',
                'name': playlist['name'] ?? 'Unknown Playlist',
                'description': playlist['description'] ?? '',
                'imageUrl': _getImageUrl(playlist['images']),
                'tracksTotal': playlist['tracks']?['total'] ?? 0,
              },
            )
            .toList();
      } else {
        debugPrint('Failed to get featured playlists: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting featured playlists: $e');
      return [];
    }
  }

  // Helper method to safely extract image URL
  String? _getImageUrl(dynamic images) {
    if (images == null) return null;
    if (images is List && images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is Map && firstImage['url'] != null) {
        return firstImage['url'] as String;
      }
    }
    return null;
  }

  // Remove duplicate tracks
  List<MusicTrack> _removeDuplicates(List<MusicTrack> tracks) {
    final seen = <String>{};
    return tracks.where((track) => seen.add(track.id)).toList();
  }

  // Play track - open in Spotify
  Future<void> playTrack(MusicTrack track) async {
    try {
      if (track.spotifyUrl != null && track.spotifyUrl!.isNotEmpty) {
        final uri = Uri.parse(track.spotifyUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('Opening in Spotify: ${track.spotifyUrl}');
        } else {
          debugPrint('Cannot launch Spotify URL: ${track.spotifyUrl}');
        }
      } else {
        debugPrint('No Spotify URL available for: ${track.title}');
      }
    } catch (e) {
      debugPrint('Error opening Spotify: $e');
    }
  }

  // Map Spotify track to MusicTrack model with better null safety
  MusicTrack _mapSpotifyTrackToMusicTrack(Map<String, dynamic> spotifyTrack) {
    try {
      final artists = (spotifyTrack['artists'] as List? ?? []).where((artist) => artist != null && artist['name'] != null).map((artist) => artist['name'] as String).join(', ');

      final album = spotifyTrack['album'] as Map<String, dynamic>? ?? {};
      final albumName = album['name'] as String? ?? 'Unknown Album';

      final imageUrl = _getImageUrl(album['images']);

      final durationMs = spotifyTrack['duration_ms'] as int? ?? 0;
      final durationFormatted = _formatDuration(durationMs);

      return MusicTrack(
        id: spotifyTrack['id'] as String? ?? '',
        title: spotifyTrack['name'] as String? ?? 'Unknown Track',
        artist: artists.isNotEmpty ? artists : 'Unknown Artist',
        album: albumName,
        duration: durationFormatted,
        imageUrl: imageUrl ?? 'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=♪',
        previewUrl: spotifyTrack['preview_url'] as String?,
        spotifyUrl: spotifyTrack['external_urls']?['spotify'] as String?,
      );
    } catch (e) {
      debugPrint('Error mapping Spotify track: $e');
      // Return a default track if mapping fails
      return MusicTrack(
        id: 'unknown',
        title: 'Unknown Track',
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        duration: '0:00',
        imageUrl: 'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=♪',
        previewUrl: null,
        spotifyUrl: null,
      );
    }
  }

  // Format duration from milliseconds to MM:SS
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Clear authentication
  void clearAuth() {
    _accessToken = null;
    _tokenExpiry = null;
  }
}
