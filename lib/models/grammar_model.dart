class GrammarInfo {
  final String rootAr;
  final String rootEn;
  final String meaningEn;
  final String meaningIn;
  final String wordAr;
  final String grammarFormDesc;
  // Tambahkan field lain jika perlu

  GrammarInfo({
    required this.rootAr,
    required this.rootEn,
    required this.meaningEn,
    required this.meaningIn,
    required this.wordAr,
    required this.grammarFormDesc,
  });

  // Factory constructor untuk membuat instance dari Map (hasil query DB)
  factory GrammarInfo.fromMap(Map<String, dynamic> map) {
    return GrammarInfo(
      rootAr: map['RootAr'] ?? '',
      rootEn: map['RootEn'] ?? '',
      meaningEn: map['MeaningEn'] ?? '',
      meaningIn: map['MeaningID'] ?? '',
      wordAr: map['WordAr'] ?? '',
      grammarFormDesc: map['GrammarFormDesc'] ?? 'N/A',
    );
  }
}