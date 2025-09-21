// spotify_config.dart
// Configuration file for Spotify API integration

class SpotifyConfig {
  // TODO: Replace with your actual Spotify API credentials
  // Get these from: https://developer.spotify.com/dashboard/applications

  static const String clientId = 'f81b3a0fb30041ebb1041f184262380a';
  static const String clientSecret = '39ef064a6e47480989e38bf89d3364f0';

  // Optional: If you plan to use user authentication later
  static const String redirectUri = 'moodscope://callback';

  // Spotify API endpoints
  static const String tokenEndpoint = 'https://accounts.spotify.com/api/token';
  static const String apiBaseUrl = 'https://api.spotify.com/v1';

  // Default market for search results (ISO 3166-1 alpha-2 country code)
  static const String defaultMarket = 'US';

  // Audio feature parameters for emotion-based recommendations
  static const Map<String, Map<String, dynamic>> emotionAudioFeatures = {
    'happy': {
      'target_valence': 0.8, // Positivity (0.0 to 1.0)
      'target_energy': 0.7, // Energy level
      'target_danceability': 0.8, // How suitable for dancing
      'target_tempo': 120, // BPM
      'seed_genres': 'pop,dance,funk,disco,happy',
    },
    'sad': {
      'target_valence': 0.2,
      'target_energy': 0.3,
      'target_acousticness': 0.8, // Acoustic vs electronic
      'target_instrumentalness': 0.3,
      'seed_genres': 'blues,folk,indie,alternative,sad',
    },
    'angry': {
      'target_valence': 0.3,
      'target_energy': 0.9,
      'target_loudness': -5, // Volume in dB
      'target_tempo': 140,
      'seed_genres': 'metal,rock,punk,hardcore,aggressive',
    },
    'neutral': {
      'target_valence': 0.5,
      'target_energy': 0.5,
      'target_acousticness': 0.6,
      'target_instrumentalness': 0.4,
      'seed_genres': 'ambient,chill,lo-fi,instrumental,relaxing',
    },
    'surprised': {
      'target_valence': 0.6,
      'target_energy': 0.6,
      'target_instrumentalness': 0.3,
      'target_tempo': 110,
      'seed_genres': 'electronic,experimental,progressive,jazz,eclectic',
    },
    'fear': {
      'target_valence': 0.2,
      'target_energy': 0.4,
      'target_acousticness': 0.7,
      'target_instrumentalness': 0.5,
      'seed_genres': 'ambient,dark-ambient,post-rock,indie,atmospheric',
    },
    'disgust': {'target_valence': 0.3, 'target_energy': 0.6, 'target_loudness': -8, 'target_tempo': 100, 'seed_genres': 'industrial,darkwave,gothic,alternative,dark'},
  };

  // Validation method
  static bool get isConfigured {
    return clientId != 'YOUR_SPOTIFY_CLIENT_ID' && clientSecret != 'YOUR_SPOTIFY_CLIENT_SECRET' && clientId.isNotEmpty && clientSecret.isNotEmpty;
  }

  // Get audio features for emotion
  static Map<String, dynamic>? getEmotionAudioFeatures(String emotion) {
    return emotionAudioFeatures[emotion.toLowerCase()];
  }

  // Get all available emotions
  static List<String> get supportedEmotions {
    return emotionAudioFeatures.keys.toList();
  }
}

/*
SETUP INSTRUCTIONS:

1. Go to https://developer.spotify.com/dashboard/applications
2. Log in with your Spotify account
3. Create a new app
4. Copy the Client ID and Client Secret
5. Replace 'YOUR_SPOTIFY_CLIENT_ID' and 'YOUR_SPOTIFY_CLIENT_SECRET' with your actual credentials

IMPORTANT NOTES:

- Never commit actual credentials to version control
- For production apps, store credentials in environment variables or secure configuration
- The Client Credentials flow used here provides access to public data only
- For user-specific features (playlists, saved tracks), you'll need to implement Authorization Code flow

EXAMPLE USAGE:

```dart
// Check if Spotify is configured
if (SpotifyConfig.isConfigured) {
  final spotifyService = SpotifyService();
  final recommendations = await spotifyService.getRecommendations('happy');
} else {
  print('Spotify API not configured. Please add your credentials.');
}
```

TESTING WITHOUT SPOTIFY:

If you want to test the app without setting up Spotify API:
1. In enhanced_music_provider.dart, modify _getSpotifyRecommendations to throw an exception
2. The provider will automatically fall back to mock data
3. This allows you to test the UI and emotion detection features

PERMISSIONS:

The current implementation uses Client Credentials flow which provides:
- Search for tracks, albums, artists
- Get track/album/artist information  
- Get audio features and analysis
- Get recommendations
- Access to public playlists

It does NOT provide:
- Access to user's private playlists
- Ability to save tracks to user's library
- Playback control
- User's listening history

For these features, you would need to implement Authorization Code flow with PKCE.
*/
