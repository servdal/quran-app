// dzikr_data.dart

class DzikrItem {
  final int? surahId;
  final int? ayahNumber;
  final int repetitions;
  final String titleId; // العنوان بالإندونيسية
  final String titleEn; // العنوان بالإنجليزية
  final bool isFullSurah;
  final String? arabicText;

  DzikrItem({
    this.surahId,
    this.ayahNumber,
    required this.repetitions,
    required this.titleId,
    required this.titleEn,
    this.isFullSurah = false,
    this.arabicText,
  });

  // وظيفة للحصول على العنوان بناءً على اللغة المختارة
  String getTitle(String langCode) {
    return langCode == 'en' ? titleEn : titleId;
  }
}

// ===== DZIKIR PAGI & PETANG (AL-QUR'AN) =====
// ملاحظة: تم توحيد القائمة لأن المحتوى من القرآن غالباً ما يكون متطابقاً
List<DzikrItem> _buildQuranDzikr() => [
  DzikrItem(
    surahId: 1, 
    repetitions: 1, 
    titleId: "Surah Al-Fatihah", 
    titleEn: "Surah Al-Fatihah", 
    isFullSurah: true
  ),
  DzikrItem(
    surahId: 2, 
    ayahNumber: 255, 
    repetitions: 1, 
    titleId: "Ayat Kursi", 
    titleEn: "Ayat Al-Kursi"
  ),
  DzikrItem(
    surahId: 2, 
    ayahNumber: 285, 
    repetitions: 1, 
    titleId: "2 Ayat Terakhir Al-Baqarah", 
    titleEn: "Last 2 Verses of Al-Baqarah"
  ),
  DzikrItem(
    surahId: 2, 
    ayahNumber: 286, 
    repetitions: 1, 
    titleId: "Al-Baqarah: 286", 
    titleEn: "Al-Baqarah: 286"
  ),
  DzikrItem(
    surahId: 112, 
    repetitions: 3, 
    titleId: "Surah Al-Ikhlas", 
    titleEn: "Surah Al-Ikhlas", 
    isFullSurah: true
  ),
  DzikrItem(
    surahId: 113, 
    repetitions: 3, 
    titleId: "Surah Al-Falaq", 
    titleEn: "Surah Al-Falaq", 
    isFullSurah: true
  ),
  DzikrItem(
    surahId: 114, 
    repetitions: 3, 
    titleId: "Surah An-Nas", 
    titleEn: "Surah An-Nas", 
    isFullSurah: true
  ),
];

final List<DzikrItem> dzikirPagiList = _buildQuranDzikr();
final List<DzikrItem> dzikirPetangList = _buildQuranDzikr();

// ===== DZIKIR PAGI LENGKAP =====
final List<DzikrItem> dzikirPagiLengkapList = [
  DzikrItem(
    repetitions: 1,
    titleId: "Ta'awudz",
    titleEn: "Seeking Refuge",
    arabicText: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ",
  ),
  ...dzikirPagiList,
  DzikrItem(
    repetitions: 1,
    titleId: "Doa Pagi Hari",
    titleEn: "Morning Supplication",
    arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ...",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Doa Pagi & Petang",
    titleEn: "Morning & Evening Prayer",
    arabicText: "اَللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا...",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Sayyidul Istighfar",
    titleEn: "The Best Prayer for Forgiveness",
    arabicText: "اَللَّهُمَّ أَنْتَ رَبِّيْ لاَ إِلَـهَ إِلاَّ أَنْتَ...",
  ),
  DzikrItem(
    repetitions: 4,
    titleId: "Permohonan Pembebasan dari Neraka",
    titleEn: "Seeking Freedom from Hellfire",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَصْبَحْتُ أُشْهِدُكَ...",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Permohonan Keselamatan",
    titleEn: "Supplication for Well-being",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ...",
  ),
  DzikrItem(
    repetitions: 3,
    titleId: "Perlindungan dari Bahaya",
    titleEn: "Protection Against Harm",
    arabicText: "بِسْمِ اللَّهِ الَّذِى لاَ يَضُرُّ مَعَ اسْمِهِ شَىْءٌ...",
  ),
  DzikrItem(
    repetitions: 3,
    titleId: "Pernyataan Ridha",
    titleEn: "Expression of Contentment",
    arabicText: "رَضِيْتُ بِاللهِ رَبًّا، وَبِاْلإِسْلاَمِ دِيْنًا...",
  ),
  DzikrItem(
    repetitions: 100,
    titleId: "Tasbih",
    titleEn: "Glorification (Tasbih)",
    arabicText: "سُبْحَانَ اللهِ وَبِحَمْدِهِ",
  ),
  DzikrItem(
    repetitions: 100,
    titleId: "Istighfar",
    titleEn: "Seeking Forgiveness",
    arabicText: "أَسْتَغْفِرُ اللهَ وَأَتُوْبُ إِلَيْهِ",
  ),
];

// ===== DZIKIR PETANG LENGKAP (AL-QUR'AN & HADITS) =====
final List<DzikrItem> dzikirPetangLengkapList = [
  DzikrItem(
    repetitions: 1,
    titleId: "Ta'awudz",
    titleEn: "Seeking Refuge",
    arabicText: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ",
  ),
  ...dzikirPetangList, // Mengambil list dari Al-Qur'an (Fatihah, Kursi, 3 Qul, dll)
  DzikrItem(
    repetitions: 1,
    titleId: "Doa Petang Hari",
    titleEn: "Evening Supplication",
    arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ للهِ، وَالْحَمْدُ للهِ، لَا إِلَهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُبِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُبِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُبِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Doa Pagi & Petang",
    titleEn: "Morning & Evening Prayer",
    arabicText: "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيْرُ",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Sayyidul Istighfar",
    titleEn: "The Chief of Seeking Forgiveness",
    arabicText: "اَللَّهُمَّ أَنْتَ رَبِّيْ لاَ إِلَـهَ إِلاَّ أَنْتَ، خَلَقْتَنِيْ وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطعتُ، أَعُوْذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوْءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوْءُ بِذَنْبِيْ فَاغْفِرْ لِيْ فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوْبَ إِلاَّ أَنْتَ",
  ),
  DzikrItem(
    repetitions: 4,
    titleId: "Permohonan Pembebasan dari Neraka",
    titleEn: "Seeking Freedom from Hellfire",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَمْسَيْتُ أُشْهِدُكَ وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتَكَ وَجَمِيْعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللهُ لاَ إِلَـهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيْكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُوْلُكَ",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Pujian atas Nikmat",
    titleEn: "Gratitude for Blessings",
    arabicText: "اَللَّهُمَّ مَا أَمْسَى بِيْ مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لاَ شَرِيْكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ",
  ),
  DzikrItem(
    repetitions: 3,
    titleId: "Permohonan Kesehatan & Perlindungan",
    titleEn: "Supplication for Health & Protection",
    arabicText: "اَللَّهُمَّ عَافِنِيْ فِيْ بَدَنِيْ، اَللَّهُمَّ عَافِنِيْ فِيْ سَمْعِيْ، اَللَّهُمَّ عَافِنِيْ فِيْ بَصَرِيْ، لاَ إِلَـهَ إِلاَّ أَنْتَ. اَللَّهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوْذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لاَ إِلَـهَ إِلاَّ أَنْتَ",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Permohonan Keselamatan",
    titleEn: "Supplication for Well-being",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَاْلآخِرَةِ، اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِيْنِيْ وَدُنْيَايَ وَأَهْلِيْ وَمَالِيْ اللَّهُمَّ اسْتُرْ عَوْرَاتِى وَآمِنْ رَوْعَاتِى. اَللَّهُمَّ احْفَظْنِيْ مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِيْ، وَعَنْ يَمِيْنِيْ وَعَنْ شِمَالِيْ، وَمِنْ فَوْقِيْ، وَأَعُوْذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِيْ",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Doa Perlindungan",
    titleEn: "Prayer for Protection",
    arabicText: "اَللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَاْلأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيْكَهُ، أَشْهَدُ أَنْ لاَ إِلَـهَ إِلاَّ أَنْتَ، أَعُوْذُ بِكَ مِنْ شَرِّ نَفْسِيْ، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِيْ سُوْءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
  ),
  DzikrItem(
    repetitions: 3,
    titleId: "Perlindungan dari Bahaya",
    titleEn: "Protection Against Harm",
    arabicText: "بِسْمِ اللَّهِ الَّذِى لاَ يَضُرُّ مَعَ اسْمِهِ شَىْءٌ فِى الأَرْضِ وَلاَ فِى السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
  ),
  DzikrItem(
    repetitions: 3,
    titleId: "Pernyataan Ridha",
    titleEn: "Expression of Contentment",
    arabicText: "رَضِيْتُ بِاللهِ رَبًّا، وَبِاْلإِسْلاَمِ دِيْنًا، وَبِمُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا",
  ),
  DzikrItem(
    repetitions: 1,
    titleId: "Permohonan Pertolongan",
    titleEn: "Supplication for Help",
    arabicText: "يَا حَيُّ يَا قَيُّوْمُ بِرَحْمَتِكَ أَسْتَغِيْثُ، وَأَصْلِحْ لِيْ شَأْنِيْ كُلَّهُ وَلاَ تَكِلْنِيْ إِلَى نَفْسِيْ طَرْفَةَ عَيْنٍ أَبَدًا",
  ),
  DzikrItem(
    repetitions: 100,
    titleId: "Tasbih",
    titleEn: "Glorification (Tasbih)",
    arabicText: "سُبْحَانَ اللهِ وَبِحَمْدِهِ",
  ),
  DzikrItem(
    repetitions: 10,
    titleId: "Tahlil",
    titleEn: "Declaration of Monotheism (Tahlil)",
    arabicText: "لاَ إِلَـهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرُ",
  ),
  DzikrItem(
    repetitions: 3,
    titleId: "Perlindungan dari Kejahatan Makhluk",
    titleEn: "Refuge from the Evil of Creation",
    arabicText: "أَعُوْذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
  ),
  DzikrItem(
    repetitions: 100,
    titleId: "Istighfar",
    titleEn: "Seeking Forgiveness",
    arabicText: "أَسْتَغْفِرُ اللهَ وَأَتُوْبُ إِلَيْهِ",
  ),
  DzikrItem(
    repetitions: 10,
    titleId: "Shalawat Nabi",
    titleEn: "Blessings upon the Prophet",
    arabicText: "اَللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
  ),
];