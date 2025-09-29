// lib/models/page_index_model.dart

class PageIndexInfo {
  final int pageNumber;
  final int juzId;
  final String firstAyah;
  final String lastAyah;

  PageIndexInfo({
    required this.pageNumber,
    required this.juzId,
    required this.firstAyah,
    required this.lastAyah,
  });

  factory PageIndexInfo.fromJson(Map<String, dynamic> json) {
    return PageIndexInfo(
      pageNumber: json['page_number'],
      juzId: json['juz_id'],
      firstAyah: json['first_ayah'],
      lastAyah: json['last_ayah'],
    );
  }
}