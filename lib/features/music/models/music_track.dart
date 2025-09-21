class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String? imageUrl;
  final String? previewUrl;
  final String? spotifyUrl;
  final double? popularity;
  final bool? explicit;
  final List<String>? genres;
  final Map<String, dynamic>? audioFeatures;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.imageUrl,
    this.previewUrl,
    this.spotifyUrl,
    this.popularity,
    this.explicit,
    this.genres,
    this.audioFeatures,
  });

  // Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'imageUrl': imageUrl,
      'previewUrl': previewUrl,
      'spotifyUrl': spotifyUrl,
      'popularity': popularity,
      'explicit': explicit,
      'genres': genres,
      'audioFeatures': audioFeatures,
    };
  }

  // Create from Map (Firestore data)
  factory MusicTrack.fromMap(Map<String, dynamic> map) {
    return MusicTrack(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      album: map['album'] ?? '',
      duration: map['duration'] ?? '',
      imageUrl: map['imageUrl'],
      previewUrl: map['previewUrl'],
      spotifyUrl: map['spotifyUrl'],
      popularity: map['popularity']?.toDouble(),
      explicit: map['explicit'],
      genres: map['genres'] != null ? List<String>.from(map['genres']) : null,
      audioFeatures: map['audioFeatures'] != null ? Map<String, dynamic>.from(map['audioFeatures']) : null,
    );
  }

  // Create copy with modifications
  MusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? duration,
    String? imageUrl,
    String? previewUrl,
    String? spotifyUrl,
    double? popularity,
    bool? explicit,
    List<String>? genres,
    Map<String, dynamic>? audioFeatures,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
      popularity: popularity ?? this.popularity,
      explicit: explicit ?? this.explicit,
      genres: genres ?? this.genres,
      audioFeatures: audioFeatures ?? this.audioFeatures,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MusicTrack && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MusicTrack(id: $id, title: $title, artist: $artist, album: $album)';
  }

  // Helper getters
  String get displayArtist => artist.length > 30 ? '${artist.substring(0, 30)}...' : artist;
  String get displayTitle => title.length > 25 ? '${title.substring(0, 25)}...' : title;
  String get displayAlbum => album.length > 25 ? '${album.substring(0, 25)}...' : album;

  bool get hasPreview => previewUrl != null && previewUrl!.isNotEmpty;
  bool get hasSpotifyUrl => spotifyUrl != null && spotifyUrl!.isNotEmpty;
  bool get isExplicit => explicit == true;

  String get popularityText {
    if (popularity == null) return 'Unknown';
    if (popularity! >= 80) return 'Very Popular';
    if (popularity! >= 60) return 'Popular';
    if (popularity! >= 40) return 'Moderate';
    if (popularity! >= 20) return 'Niche';
    return 'Underground';
  }

  // Get audio feature as string for display
  String getAudioFeatureDisplay(String feature) {
    if (audioFeatures == null || !audioFeatures!.containsKey(feature)) {
      return 'N/A';
    }

    final value = audioFeatures![feature];
    if (value is double) {
      return '${(value * 100).toInt()}%';
    }
    return value.toString();
  }

  // Get mood description based on audio features
  String get moodDescription {
    if (audioFeatures == null) return 'Unknown mood';

    final valence = audioFeatures!['valence'] as double? ?? 0.5;
    final energy = audioFeatures!['energy'] as double? ?? 0.5;
    final danceability = audioFeatures!['danceability'] as double? ?? 0.5;

    if (valence > 0.7 && energy > 0.7) return 'Happy & Energetic';
    if (valence > 0.7 && danceability > 0.7) return 'Joyful & Danceable';
    if (valence < 0.3 && energy < 0.4) return 'Sad & Mellow';
    if (energy > 0.8) return 'High Energy';
    if (valence < 0.3) return 'Melancholic';
    if (danceability > 0.8) return 'Very Danceable';
    if (valence > 0.6) return 'Positive';

    return 'Balanced mood';
  }
}
