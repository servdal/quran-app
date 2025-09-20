class DzikrItem {
  final int surahId;
  final int? ayahNumber;
  final int repetitions;
  final String title;
  final bool isFullSurah;

  DzikrItem({
    required this.surahId,
    this.ayahNumber,
    required this.repetitions,
    required this.title,
    this.isFullSurah = false,
  });
}

final List<DzikrItem> dzikirPagiList = [
  DzikrItem(surahId: 1, repetitions: 1, title: "Surah Al-Fatihah", isFullSurah: true),
  DzikrItem(surahId: 2, ayahNumber: 255, repetitions: 1, title: "Ayat Kursi"),
  DzikrItem(surahId: 2, ayahNumber: 285, repetitions: 1, title: "2 Ayat Terakhir Al-Baqarah"),
  DzikrItem(surahId: 2, ayahNumber: 286, repetitions: 1, title: ""),
  DzikrItem(surahId: 112, repetitions: 3, title: "Surah Al-Ikhlas", isFullSurah: true),
  DzikrItem(surahId: 113, repetitions: 3, title: "Surah Al-Falaq", isFullSurah: true),
  DzikrItem(surahId: 114, repetitions: 3, title: "Surah An-Nas", isFullSurah: true),
  DzikrItem(surahId: 3, ayahNumber: 190, repetitions: 1, title: "Surah Ali Imran 190-191"),
  DzikrItem(surahId: 3, ayahNumber: 191, repetitions: 1, title: ""),
  DzikrItem(surahId: 7, ayahNumber: 205, repetitions: 1, title: "Surah Al-A’raf 205"),
];

final List<DzikrItem> dzikirPetangList = [
  DzikrItem(surahId: 1, repetitions: 1, title: "Surah Al-Fatihah", isFullSurah: true),
  DzikrItem(surahId: 2, ayahNumber: 255, repetitions: 1, title: "Ayat Kursi"),
  DzikrItem(surahId: 2, ayahNumber: 285, repetitions: 1, title: "2 Ayat Terakhir Al-Baqarah"),
  DzikrItem(surahId: 2, ayahNumber: 286, repetitions: 1, title: ""),
  DzikrItem(surahId: 112, repetitions: 3, title: "Surah Al-Ikhlas", isFullSurah: true),
  DzikrItem(surahId: 113, repetitions: 3, title: "Surah Al-Falaq", isFullSurah: true),
  DzikrItem(surahId: 114, repetitions: 3, title: "Surah An-Nas", isFullSurah: true),
  DzikrItem(surahId: 7, ayahNumber: 205, repetitions: 1, title: "Surah Al-A’raf 205"),
  DzikrItem(surahId: 33, ayahNumber: 41, repetitions: 1, title: "Surah Al-Ahzab 41-42"),
  DzikrItem(surahId: 33, ayahNumber: 42, repetitions: 1, title: ""),
  DzikrItem(surahId: 40, ayahNumber: 55, repetitions: 1, title: "Surah Ghafir 55"),
];