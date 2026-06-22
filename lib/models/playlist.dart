class Playlist {
  final String id;
  final String name;
  final List<String> trackPaths;
  final DateTime createdAt;
  final String? coverArtPath;

  const Playlist({
    required this.id,
    required this.name,
    this.trackPaths = const [],
    required this.createdAt,
    this.coverArtPath,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? trackPaths,
    DateTime? createdAt,
    String? coverArtPath,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      trackPaths: trackPaths ?? this.trackPaths,
      createdAt: createdAt ?? this.createdAt,
      coverArtPath: coverArtPath ?? this.coverArtPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trackPaths': trackPaths,
    'createdAt': createdAt.millisecondsSinceEpoch,
    if (coverArtPath != null) 'coverArtPath': coverArtPath,
  };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      trackPaths: (json['trackPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      coverArtPath: json['coverArtPath'] as String?,
    );
  }

  @override
  String toString() => 'Playlist(id: $id, name: $name, tracks: ${trackPaths.length})';
}
