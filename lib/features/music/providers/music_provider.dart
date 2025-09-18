import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../models/music_track.dart';

class MusicProvider extends ChangeNotifier {
  List<MusicTrack> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentEmotion = 'neutral';

  List<MusicTrack> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentEmotion => _currentEmotion;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Get music recommendations based on emotion
  Future<void> getRecommendations(String emotion) async {
    try {
      _setLoading(true);
      _setError(null);
      _currentEmotion = emotion;

      // Since we don't have actual Spotify API integration,
      // we'll generate mock recommendations based on emotion
      _recommendations = _generateMockRecommendations(emotion);

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      _setError('Failed to load music recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Generate mock music recommendations
  List<MusicTrack> _generateMockRecommendations(String emotion) {
    final mockTracks = <String, List<Map<String, String>>>{
      'happy': [
        {'title': 'Good as Hell', 'artist': 'Lizzo', 'album': 'Cuz I Love You', 'duration': '3:39', 'imageUrl': 'https://via.placeholder.com/300x300/FFD700/000000?text=♪'},
        {'title': 'Happy', 'artist': 'Pharrell Williams', 'album': 'Despicable Me 2', 'duration': '3:53', 'imageUrl': 'https://via.placeholder.com/300x300/FF6B6B/FFFFFF?text=♪'},
        {
          'title': 'Can\'t Stop the Feeling!',
          'artist': 'Justin Timberlake',
          'album': 'Trolls',
          'duration': '3:56',
          'imageUrl': 'https://via.placeholder.com/300x300/4ECDC4/FFFFFF?text=♪',
        },
        {
          'title': 'Uptown Funk',
          'artist': 'Mark Ronson ft. Bruno Mars',
          'album': 'Uptown Special',
          'duration': '4:30',
          'imageUrl': 'https://via.placeholder.com/300x300/45B7D1/FFFFFF?text=♪',
        },
      ],
      'sad': [
        {'title': 'Someone Like You', 'artist': 'Adele', 'album': '21', 'duration': '4:45', 'imageUrl': 'https://via.placeholder.com/300x300/6C7CE0/FFFFFF?text=♪'},
        {'title': 'Mad World', 'artist': 'Gary Jules', 'album': 'Donnie Darko', 'duration': '3:07', 'imageUrl': 'https://via.placeholder.com/300x300/A8E6CF/000000?text=♪'},
        {'title': 'Hurt', 'artist': 'Johnny Cash', 'album': 'American IV', 'duration': '3:38', 'imageUrl': 'https://via.placeholder.com/300x300/FFB6C1/000000?text=♪'},
        {'title': 'Black', 'artist': 'Pearl Jam', 'album': 'Ten', 'duration': '5:43', 'imageUrl': 'https://via.placeholder.com/300x300/DDA0DD/000000?text=♪'},
      ],
      'angry': [
        {'title': 'Break Stuff', 'artist': 'Limp Bizkit', 'album': 'Significant Other', 'duration': '2:47', 'imageUrl': 'https://via.placeholder.com/300x300/FF4757/FFFFFF?text=♪'},
        {'title': 'Bodies', 'artist': 'Drowning Pool', 'album': 'Sinner', 'duration': '3:21', 'imageUrl': 'https://via.placeholder.com/300x300/2F3542/FFFFFF?text=♪'},
        {'title': 'Chop Suey!', 'artist': 'System of a Down', 'album': 'Toxicity', 'duration': '3:30', 'imageUrl': 'https://via.placeholder.com/300x300/FF3838/FFFFFF?text=♪'},
        {'title': 'One Step Closer', 'artist': 'Linkin Park', 'album': 'Hybrid Theory', 'duration': '2:36', 'imageUrl': 'https://via.placeholder.com/300x300/FF9F43/000000?text=♪'},
      ],
      'neutral': [
        {'title': 'Weightless', 'artist': 'Marconi Union', 'album': 'Weightless', 'duration': '8:10', 'imageUrl': 'https://via.placeholder.com/300x300/95A5A6/FFFFFF?text=♪'},
        {
          'title': 'Clair de Lune',
          'artist': 'Claude Debussy',
          'album': 'Classical Essentials',
          'duration': '5:05',
          'imageUrl': 'https://via.placeholder.com/300x300/BDC3C7/000000?text=♪',
        },
        {'title': 'Aqueous Transmission', 'artist': 'Incubus', 'album': 'Morning View', 'duration': '7:49', 'imageUrl': 'https://via.placeholder.com/300x300/74B9FF/FFFFFF?text=♪'},
        {'title': 'Porcelain', 'artist': 'Moby', 'album': 'Play', 'duration': '4:01', 'imageUrl': 'https://via.placeholder.com/300x300/00B894/FFFFFF?text=♪'},
      ],
      'surprised': [
        {
          'title': 'Bohemian Rhapsody',
          'artist': 'Queen',
          'album': 'A Night at the Opera',
          'duration': '5:55',
          'imageUrl': 'https://via.placeholder.com/300x300/E17055/FFFFFF?text=♪',
        },
        {
          'title': 'Welcome to the Machine',
          'artist': 'Pink Floyd',
          'album': 'Wish You Were Here',
          'duration': '7:31',
          'imageUrl': 'https://via.placeholder.com/300x300/6C5CE7/FFFFFF?text=♪',
        },
        {'title': 'Paranoid Android', 'artist': 'Radiohead', 'album': 'OK Computer', 'duration': '6:23', 'imageUrl': 'https://via.placeholder.com/300x300/A29BFE/FFFFFF?text=♪'},
        {'title': 'Close to the Edge', 'artist': 'Yes', 'album': 'Close to the Edge', 'duration': '18:42', 'imageUrl': 'https://via.placeholder.com/300x300/FD79A8/FFFFFF?text=♪'},
      ],
      'fear': [
        {'title': 'Breathe Me', 'artist': 'Sia', 'album': '1000 Forms of Fear', 'duration': '4:31', 'imageUrl': 'https://via.placeholder.com/300x300/636E72/FFFFFF?text=♪'},
        {
          'title': 'Heavy',
          'artist': 'Linkin Park ft. Kiiara',
          'album': 'One More Light',
          'duration': '2:49',
          'imageUrl': 'https://via.placeholder.com/300x300/2D3436/FFFFFF?text=♪',
        },
        {'title': 'Anxiety', 'artist': 'Julia Michaels', 'album': 'Nervous System', 'duration': '3:27', 'imageUrl': 'https://via.placeholder.com/300x300/00CEC9/FFFFFF?text=♪'},
        {
          'title': 'Safe & Sound',
          'artist': 'Capital Cities',
          'album': 'In a Tidal Wave of Mystery',
          'duration': '3:13',
          'imageUrl': 'https://via.placeholder.com/300x300/55EFC4/000000?text=♪',
        },
      ],
      'disgust': [
        {'title': 'Toxic', 'artist': 'Britney Spears', 'album': 'In the Zone', 'duration': '3:19', 'imageUrl': 'https://via.placeholder.com/300x300/00B894/FFFFFF?text=♪'},
        {
          'title': 'Bad Guy',
          'artist': 'Billie Eilish',
          'album': 'When We All Fall Asleep',
          'duration': '3:14',
          'imageUrl': 'https://via.placeholder.com/300x300/81ECEC/000000?text=♪',
        },
        {'title': 'Dirty', 'artist': 'Christina Aguilera', 'album': 'Stripped', 'duration': '4:58', 'imageUrl': 'https://via.placeholder.com/300x300/FDCB6E/000000?text=♪'},
        {
          'title': 'Tainted Love',
          'artist': 'Soft Cell',
          'album': 'Non-Stop Erotic Cabaret',
          'duration': '2:40',
          'imageUrl': 'https://via.placeholder.com/300x300/E84393/FFFFFF?text=♪',
        },
      ],
    };

    final tracks = mockTracks[emotion] ?? mockTracks['neutral']!;
    return tracks
        .map(
          (track) => MusicTrack(
            id: track['title']!.toLowerCase().replaceAll(' ', '_'),
            title: track['title']!,
            artist: track['artist']!,
            album: track['album']!,
            duration: track['duration']!,
            imageUrl: track['imageUrl']!,
            previewUrl: null, // Would be actual preview URL in real implementation
          ),
        )
        .toList();
  }

  // Play track (mock implementation)
  Future<void> playTrack(MusicTrack track) async {
    // In a real implementation, this would integrate with music player APIs
    // For now, we'll just show a message
    print('Playing: ${track.title} by ${track.artist}');
  }

  // Search tracks (mock implementation)
  Future<List<MusicTrack>> searchTracks(String query) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate search delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock search results
      final searchResults = <MusicTrack>[];

      // Search through all emotions and return matching tracks
      for (final emotion in AppConstants.emotionLabels) {
        final emotionTracks = _generateMockRecommendations(emotion);
        for (final track in emotionTracks) {
          if (track.title.toLowerCase().contains(query.toLowerCase()) ||
              track.artist.toLowerCase().contains(query.toLowerCase()) ||
              track.album.toLowerCase().contains(query.toLowerCase())) {
            searchResults.add(track);
          }
        }
      }

      return searchResults.take(10).toList(); // Limit to 10 results
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
