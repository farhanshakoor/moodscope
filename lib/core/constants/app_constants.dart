class AppConstants {
  // App Info
  static const String appName = 'MoodScope';
  static const String appVersion = '1.0.0';

  // Emotion Labels (matching your TFLite model)
  static const List<String> emotionLabels = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprised'];

  // Emotion Emojis
  static const Map<String, String> emotionEmojis = {'happy': '😊', 'sad': '😢', 'angry': '😠', 'neutral': '😐', 'surprised': '😲', 'fear': '😨', 'disgust': '🤢'};

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String emotionEntriesCollection = 'emotion_entries';
  static const String diaryEntriesCollection = 'diary_entries';

  // Shared Preferences Keys
  static const String isFirstTimeKey = 'is_first_time';
  static const String userIdKey = 'user_id';
  static const String lastEmotionKey = 'last_emotion';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;

  // API Keys (Replace with your actual keys)
  static const String spotifyClientId = 'your_spotify_client_id';
  static const String spotifyClientSecret = 'your_spotify_client_secret';

  // Music Recommendations based on emotions
  static const Map<String, List<String>> emotionMusicGenres = {
    'happy': ['pop', 'dance', 'electronic', 'funk'],
    'sad': ['classical', 'indie', 'alternative', 'blues'],
    'angry': ['rock', 'metal', 'punk', 'hardcore'],
    'neutral': ['ambient', 'chill', 'jazz', 'acoustic'],
    'surprised': ['electronic', 'experimental', 'world'],
    'fear': ['ambient', 'dark ambient', 'minimal'],
    'disgust': ['grunge', 'alternative rock', 'industrial'],
  };

  // Motivational Messages
  static const Map<String, List<String>> emotionMessages = {
    'happy': ["Keep shining bright! ✨", "Your happiness is contagious! 😊", "You're radiating positive energy!", "What a beautiful smile you have!"],
    'sad': [
      "It's okay to feel sad sometimes. You're not alone. 💙",
      "Tomorrow is a new day with new possibilities.",
      "Your feelings are valid. Take care of yourself.",
      "This too shall pass. Stay strong! 💪",
    ],
    'angry': [
      "Take a deep breath. You've got this! 🌬️",
      "Channel that energy into something positive.",
      "It's okay to feel angry. Let's work through it.",
      "Remember, you're in control of your reactions.",
    ],
    'neutral': [
      "Balanced and steady - that's your strength! ⚖️",
      "Sometimes neutral is the perfect place to be.",
      "You're grounded and centered today.",
      "Peace and calmness suit you well.",
    ],
    'surprised': ["Life is full of wonderful surprises! 🎉", "Your curiosity makes you special!", "Embrace the unexpected moments!", "Surprise is the beginning of wonder!"],
    'fear': [
      "Courage isn't the absence of fear, but acting despite it. 🦁",
      "You're braver than you believe.",
      "Take it one step at a time.",
      "You've overcome challenges before, you can do it again!",
    ],
    'disgust': [
      "Trust your instincts - they're protecting you. 🛡️",
      "It's okay to set boundaries.",
      "Your feelings help you navigate the world.",
      "You know what's right for you.",
    ],
  };

  // Onboarding Steps
  static const List<Map<String, String>> onboardingSteps = [
    {
      'title': 'Welcome to MoodScope',
      'subtitle': 'Your personal emotion tracking companion',
      'description': 'Discover patterns in your emotions and improve your mental well-being with AI-powered insights.',
      'image': 'assets/images/onboarding_1.png',
    },
    {
      'title': 'Track Your Emotions',
      'subtitle': 'Real-time emotion detection',
      'description': 'Use your camera to detect emotions in real-time and build a comprehensive emotional diary.',
      'image': 'assets/images/onboarding_2.png',
    },
    {
      'title': 'Analyze Your Patterns',
      'subtitle': 'Insightful analytics dashboard',
      'description': 'View beautiful charts and insights about your emotional patterns over time.',
      'image': 'assets/images/onboarding_3.png',
    },
    {
      'title': 'Music for Your Mood',
      'subtitle': 'Personalized music recommendations',
      'description': 'Get music suggestions that match your current emotion and help improve your mood.',
      'image': 'assets/images/onboarding_4.png',
    },
  ];
}
