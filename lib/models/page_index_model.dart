class PageIndexInfo {
  final int pageNumber;
  final int juzId;
  final int surahId;

  PageIndexInfo({
    required this.pageNumber,
    required this.juzId,
    required this.surahId,
  });

  factory PageIndexInfo.fromJson(Map<String, dynamic> json) {
    return PageIndexInfo(
      pageNumber: json['page_number'],
      juzId: json['juz_id'],
      surahId: json['first_sura_id'] ?? 0,
    );
  }

  /// 🔥 NEW: from SQLite row
  factory PageIndexInfo.fromDb(Map<String, dynamic> row) {
    return PageIndexInfo(
      pageNumber: row['page_number'],
      juzId: row['juz_id'],
      surahId: row['sura_id'],
    );
  }
}
