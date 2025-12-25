class AudioIndex {
  final String file;

  AudioIndex({required this.file});

  factory AudioIndex.fromJson(Map<String, dynamic> json) {
    return AudioIndex(file: json['file']);
  }
}
