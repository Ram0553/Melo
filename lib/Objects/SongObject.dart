class Song {
  final String imageUrl;   // URL for the song's image
  final String title;      // Title of the song
  final String artist;     // Name of the artist
  final String album;      // Name of the album
  final String downloadUrl; // URL to download or stream the song

  Song({
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.album,
    required this.downloadUrl,
  });

  // Optional: You can add a factory method to create a Song from a Map (like from API response)
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      imageUrl: map['image'][1]['url'], // Ensure this matches your API response
      title: map['name'],
      artist: map['artists']['primary'][0]['name'],  // Adjust according to your API response
      album: map['album']['name'],    // Adjust according to your API response
      downloadUrl: map['downloadUrl'][4]['url'], // Adjust if necessary
    );
  }
}
