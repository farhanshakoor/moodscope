import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodscope/features/music/service/spotify_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/music_track.dart';
import '../../emotion_detection/models/emotion_entry.dart';

class EnhancedMusicProvider extends ChangeNotifier {
  final SpotifyService _spotifyService = SpotifyService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<MusicTrack> _recommendations = [];
  List<MusicTrack> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentEmotion = 'neutral';
  String _lastUserEmotion = 'neutral';
  DateTime _lastEmotionCheck = DateTime.now();

  // Featured content
  List<Map<String, dynamic>> _featuredPlaylists = [];
  bool _loadingPlaylists = false;

  // Getters
  List<MusicTrack> get recommendations => _recommendations;
  List<MusicTrack> get searchResults => _searchResults;
  List<Map<String, dynamic>> get featuredPlaylists => _featuredPlaylists;
  bool get isLoading => _isLoading;
  bool get loadingPlaylists => _loadingPlaylists;
  String? get errorMessage => _errorMessage;
  String get currentEmotion => _currentEmotion;
  String get lastUserEmotion => _lastUserEmotion;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Initialize and load user's last emotion-based recommendations
  Future<void> initializeWithUserEmotion() async {
    try {
      _setLoading(true);
      _setError(null);

      // Get user's most recent emotion
      final recentEmotion = await _getUserMostRecentEmotion();
      _lastUserEmotion = recentEmotion;
      _currentEmotion = recentEmotion;

      // Load recommendations based on that emotion
      await _getSpotifyRecommendations(recentEmotion);

      // Load featured playlists in background
      _loadFeaturedPlaylistsAsync();
    } catch (e) {
      _setError('Failed to initialize music recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get user's most recent emotion from Firestore
  Future<String> _getUserMostRecentEmotion() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'neutral';

      // Check if we need to refresh the emotion (every 30 minutes)
      if (DateTime.now().difference(_lastEmotionCheck).inMinutes < 30) {
        return _lastUserEmotion;
      }

      final querySnapshot = await _firestore
          .collection(AppConstants.emotionEntriesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(5) // Get last 5 entries for analysis
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 'neutral';
      }

      // Analyze recent emotions to determine current mood
      final recentEmotions = querySnapshot.docs.map((doc) => EmotionEntry.fromMap(doc.data())).toList();

      _lastEmotionCheck = DateTime.now();

      // Use the most recent emotion, but consider frequency of recent emotions
      final mostRecent = recentEmotions.first.emotion;

      // Count emotion frequency in last 5 entries
      final emotionCounts = <String, int>{};
      for (final entry in recentEmotions) {
        emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;
      }

      // If the most recent emotion appears multiple times recently, use it
      // Otherwise, use the most frequent recent emotion
      if ((emotionCounts[mostRecent] ?? 0) >= 2) {
        return mostRecent;
      } else {
        final mostFrequent = emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        return mostFrequent;
      }
    } catch (e) {
      print('Error getting user recent emotion: $e');
      return 'neutral';
    }
  }

  // Get music recommendations based on emotion using Spotify API
  Future<void> getRecommendations(String emotion) async {
    try {
      _setLoading(true);
      _setError(null);
      _currentEmotion = emotion;

      await _getSpotifyRecommendations(emotion);
    } catch (e) {
      _setError('Failed to load music recommendations: $e');
      // Fallback to mock data if Spotify fails
      _recommendations = _generateFallbackRecommendations(emotion);
    } finally {
      _setLoading(false);
    }
  }

  // Get Spotify recommendations
  Future<void> _getSpotifyRecommendations(String emotion) async {
    try {
      final tracks = await _spotifyService.getRecommendations(emotion, limit: 25);
      _recommendations = tracks;

      print('Loaded ${tracks.length} Spotify recommendations for $emotion emotion');
    } catch (e) {
      print('Spotify API error: $e');
      throw e;
    }
  }

  // Search tracks using Spotify API
  Future<List<MusicTrack>> searchTracks(String query) async {
    try {
      _setLoading(true);
      _setError(null);

      final tracks = await _spotifyService.searchTracks(query, limit: 20);
      _searchResults = tracks;

      return tracks;
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Load featured playlists asynchronously
  Future<void> _loadFeaturedPlaylistsAsync() async {
    try {
      _loadingPlaylists = true;
      notifyListeners();

      _featuredPlaylists = await _spotifyService.getFeaturedPlaylists(limit: 10);
    } catch (e) {
      print('Error loading featured playlists: $e');
    } finally {
      _loadingPlaylists = false;
      notifyListeners();
    }
  }

  // Get personalized recommendations based on listening history and current emotion
  Future<void> getPersonalizedRecommendations() async {
    try {
      _setLoading(true);
      _setError(null);

      // Get user's recent emotion pattern
      final emotionPattern = await _analyzeRecentEmotionPattern();

      // Get recommendations for the dominant emotion
      await _getSpotifyRecommendations(emotionPattern['dominantEmotion']);

      // Mix with some variety based on secondary emotions
      if (emotionPattern['secondaryEmotions'].isNotEmpty) {
        for (String secondaryEmotion in emotionPattern['secondaryEmotions']) {
          try {
            final additionalTracks = await _spotifyService.getRecommendations(secondaryEmotion, limit: 5);
            _recommendations.addAll(additionalTracks);
          } catch (e) {
            print('Error getting secondary emotion tracks: $e');
          }
        }
      }

      // Shuffle to mix different emotion-based tracks
      _recommendations.shuffle();

      // Limit to reasonable number
      if (_recommendations.length > 30) {
        _recommendations = _recommendations.take(30).toList();
      }
    } catch (e) {
      _setError('Failed to load personalized recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Analyze user's recent emotion pattern
  Future<Map<String, dynamic>> _analyzeRecentEmotionPattern() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'dominantEmotion': 'neutral', 'secondaryEmotions': <String>[]};
      }

      // Get emotions from last 7 days
      final lastWeek = DateTime.now().subtract(Duration(days: 7));

      final querySnapshot = await _firestore
          .collection(AppConstants.emotionEntriesCollection)
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeek))
          .orderBy('timestamp', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'dominantEmotion': 'neutral', 'secondaryEmotions': <String>[]};
      }

      // Count emotion frequencies
      final emotionCounts = <String, int>{};
      final emotionWeightedScores = <String, double>{};

      for (final doc in querySnapshot.docs) {
        final entry = EmotionEntry.fromMap(doc.data());
        emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;

        // Weight more recent emotions higher
        final daysSince = DateTime.now().difference(entry.timestamp).inDays;
        final weight = 1.0 / (daysSince + 1); // More recent = higher weight

        emotionWeightedScores[entry.emotion] = (emotionWeightedScores[entry.emotion] ?? 0) + (weight * entry.confidence / 100);
      }

      // Find dominant emotion
      String dominantEmotion = 'neutral';
      double highestScore = 0;

      emotionWeightedScores.forEach((emotion, score) {
        if (score > highestScore) {
          highestScore = score;
          dominantEmotion = emotion;
        }
      });

      // Find secondary emotions (those with significant presence)
      final secondaryEmotions = emotionWeightedScores.entries
          .where((entry) => entry.key != dominantEmotion && entry.value > (highestScore * 0.3)) // At least 30% of dominant emotion's score
          .map((entry) => entry.key)
          .take(2) // Limit to 2 secondary emotions
          .toList();

      return {'dominantEmotion': dominantEmotion, 'secondaryEmotions': secondaryEmotions};
    } catch (e) {
      print('Error analyzing emotion pattern: $e');
      return {'dominantEmotion': 'neutral', 'secondaryEmotions': <String>[]};
    }
  }

  // Generate fallback recommendations if Spotify API fails
  List<MusicTrack> _generateFallbackRecommendations(String emotion) {
    final mockTracks = <String, List<Map<String, String>>>{
      'happy': [
        {'title': 'Good as Hell', 'artist': 'Lizzo', 'album': 'Cuz I Love You', 'duration': '3:39'},
        {'title': 'Happy', 'artist': 'Pharrell Williams', 'album': 'Despicable Me 2', 'duration': '3:53'},
        {'title': 'Can\'t Stop the Feeling!', 'artist': 'Justin Timberlake', 'album': 'Trolls', 'duration': '3:56'},
        {'title': 'Uptown Funk', 'artist': 'Mark Ronson ft. Bruno Mars', 'album': 'Uptown Special', 'duration': '4:30'},
      ],
      'sad': [
        {'title': 'Someone Like You', 'artist': 'Adele', 'album': '21', 'duration': '4:45'},
        {'title': 'Mad World', 'artist': 'Gary Jules', 'album': 'Donnie Darko', 'duration': '3:07'},
        {'title': 'Hurt', 'artist': 'Johnny Cash', 'album': 'American IV', 'duration': '3:38'},
        {'title': 'Black', 'artist': 'Pearl Jam', 'album': 'Ten', 'duration': '5:43'},
      ],
      'angry': [
        {'title': 'Break Stuff', 'artist': 'Limp Bizkit', 'album': 'Significant Other', 'duration': '2:47'},
        {'title': 'Bodies', 'artist': 'Drowning Pool', 'album': 'Sinner', 'duration': '3:21'},
        {'title': 'Chop Suey!', 'artist': 'System of a Down', 'album': 'Toxicity', 'duration': '3:30'},
        {'title': 'One Step Closer', 'artist': 'Linkin Park', 'album': 'Hybrid Theory', 'duration': '2:36'},
      ],
      'neutral': [
        {'title': 'Weightless', 'artist': 'Marconi Union', 'album': 'Weightless', 'duration': '8:10'},
        {'title': 'Clair de Lune', 'artist': 'Claude Debussy', 'album': 'Classical Essentials', 'duration': '5:05'},
        {'title': 'Aqueous Transmission', 'artist': 'Incubus', 'album': 'Morning View', 'duration': '7:49'},
        {'title': 'Porcelain', 'artist': 'Moby', 'album': 'Play', 'duration': '4:01'},
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
            imageUrl: 'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=♪',
            previewUrl: null,
          ),
        )
        .toList();
  }

  // Play track (mock implementation - would integrate with actual player)
  Future<void> playTrack(MusicTrack track) async {
    try {
      if (track.previewUrl != null) {
        // In a real implementation, you would use an audio player
        print('Playing preview: ${track.title} by ${track.artist}');
        // Example: await audioPlayer.play(track.previewUrl!);
      } else if (track.spotifyUrl != null) {
        // Open in Spotify app or web player
        print('Opening in Spotify: ${track.spotifyUrl}');
        // Example: await launchUrl(Uri.parse(track.spotifyUrl!));
      } else {
        print('No playback options available for: ${track.title}');
      }
    } catch (e) {
      print('Error playing track: $e');
    }
  }

  // Save user's track interaction for future recommendations
  Future<void> saveTrackInteraction(MusicTrack track, String interactionType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_music_interactions').add({
        'userId': user.uid,
        'trackId': track.id,
        'trackTitle': track.title,
        'trackArtist': track.artist,
        'interactionType': interactionType, // 'play', 'like', 'skip', etc.
        'currentEmotion': _currentEmotion,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Saved interaction: $interactionType for ${track.title}');
    } catch (e) {
      print('Error saving track interaction: $e');
    }
  }

  // Refresh recommendations based on current user emotion
  Future<void> refreshBasedOnCurrentEmotion() async {
    final currentUserEmotion = await _getUserMostRecentEmotion();
    if (currentUserEmotion != _lastUserEmotion) {
      _lastUserEmotion = currentUserEmotion;
      await getRecommendations(currentUserEmotion);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults.clear();
    notifyListeners();
  }
}
