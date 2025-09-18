class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String imageUrl;
  final String? previewUrl;

  const MusicTrack({required this.id, required this.title, required this.artist, required this.album, required this.duration, required this.imageUrl, this.previewUrl});

  // Create MusicTrack from JSON (for API integration)
  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] ?? '',
      title: json['name'] ?? '',
      artist: json['artists']?[0]?['name'] ?? '',
      album: json['album']?['name'] ?? '',
      duration: _formatDuration(json['duration_ms'] ?? 0),
      imageUrl: json['album']?['images']?[0]?['url'] ?? '',
      previewUrl: json['preview_url'],
    );
  }

  // Convert MusicTrack to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'artist': artist, 'album': album, 'duration': duration, 'imageUrl': imageUrl, 'previewUrl': previewUrl};
  }

  // Format duration from milliseconds to mm:ss
  static String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MusicTrack &&
        other.id == id &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.duration == duration &&
        other.imageUrl == imageUrl &&
        other.previewUrl == previewUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ artist.hashCode ^ album.hashCode ^ duration.hashCode ^ imageUrl.hashCode ^ previewUrl.hashCode;
  }

  @override
  String toString() {
    return 'MusicTrack(id: $id, title: $title, artist: $artist, album: $album, duration: $duration)';
  }
}
