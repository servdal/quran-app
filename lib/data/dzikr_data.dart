// dzikr_data.dart

class DzikrItem {
  final int? surahId; // Dijadikan opsional
  final int? ayahNumber;
  final int repetitions;
  final String title;
  final bool isFullSurah;
  final String? arabicText; // Tambahan untuk teks dari Hadits

  DzikrItem({
    this.surahId,
    this.ayahNumber,
    required this.repetitions,
    required this.title,
    this.isFullSurah = false,
    this.arabicText,
  });
}

// ===== DZIKIR PAGI (HANYA AL-QUR'AN) =====
final List<DzikrItem> dzikirPagiList = [
  DzikrItem(surahId: 1, repetitions: 1, title: "Surah Al-Fatihah", isFullSurah: true),
  DzikrItem(surahId: 2, ayahNumber: 255, repetitions: 1, title: "Ayat Kursi"),
  DzikrItem(surahId: 2, ayahNumber: 285, repetitions: 1, title: "2 Ayat Terakhir Al-Baqarah"),
  DzikrItem(surahId: 2, ayahNumber: 286, repetitions: 1, title: ""),
  DzikrItem(surahId: 112, repetitions: 3, title: "Surah Al-Ikhlas", isFullSurah: true),
  DzikrItem(surahId: 113, repetitions: 3, title: "Surah Al-Falaq", isFullSurah: true),
  DzikrItem(surahId: 114, repetitions: 3, title: "Surah An-Nas", isFullSurah: true),
];

// ===== DZIKIR PETANG (HANYA AL-QUR'AN) =====
final List<DzikrItem> dzikirPetangList = [
  DzikrItem(surahId: 1, repetitions: 1, title: "Surah Al-Fatihah", isFullSurah: true),
  DzikrItem(surahId: 2, ayahNumber: 255, repetitions: 1, title: "Ayat Kursi"),
  DzikrItem(surahId: 2, ayahNumber: 285, repetitions: 1, title: "2 Ayat Terakhir Al-Baqarah"),
  DzikrItem(surahId: 2, ayahNumber: 286, repetitions: 1, title: ""),
  DzikrItem(surahId: 112, repetitions: 3, title: "Surah Al-Ikhlas", isFullSurah: true),
  DzikrItem(surahId: 113, repetitions: 3, title: "Surah Al-Falaq", isFullSurah: true),
  DzikrItem(surahId: 114, repetitions: 3, title: "Surah An-Nas", isFullSurah: true),
];

// ===== DZIKIR PAGI (LENGKAP: AL-QUR'AN & HADITS) =====
final List<DzikrItem> dzikirPagiLengkapList = [
  DzikrItem(
    repetitions: 1,
    title: "Ta'awudz",
    arabicText: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ",
  ),
  ...dzikirPagiList, // Mengambil semua dari list Al-Qur'an
  DzikrItem(
    repetitions: 1,
    title: "Doa Pagi Hari",
    arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَـهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرُ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِيْ هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوْذُ بِكَ مِنْ شَرِّ مَا فِيْ هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوْذُ بِكَ مِنَ الْكَسَلِ وَسُوْءِ الْكِبَرِ، رَبِّ أَعُوْذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Doa Pagi & Petang",
    arabicText: "اَللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوْتُ وَإِلَيْكَ النُّشُوْرُ",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Sayyidul Istighfar",
    arabicText: "اَللَّهُمَّ أَنْتَ رَبِّيْ لاَ إِلَـهَ إِلاَّ أَنْتَ، خَلَقْتَنِيْ وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوْذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوْءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوْءُ بِذَنْبِيْ فَاغْفِرْ لِيْ فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوْبَ إِلاَّ أَنْتَ.",
  ),
  DzikrItem(
    repetitions: 4,
    title: "Permohonan Pembebasan dari Neraka",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَصْبَحْتُ أُشْهِدُكَ وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتَكَ وَجَمِيْعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللهُ لاَ إِلَـهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيْكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُوْلُكَ",
  ),
   DzikrItem(
    repetitions: 1,
    title: "Permohonan Keselamatan",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَاْلآخِرَةِ، اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِيْنِيْ وَدُنْيَايَ وَأَهْلِيْ وَمَالِيْ اللَّهُمَّ اسْتُرْ عَوْرَاتِى وَآمِنْ رَوْعَاتِى. اَللَّهُمَّ احْفَظْنِيْ مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِيْ، وَعَنْ يَمِيْنِيْ وَعَنْ شِمَالِيْ، وَمِنْ فَوْقِيْ، وَأَعُوْذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِيْ",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Doa Perlindungan",
    arabicText: "اَللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَadَةِ فَاطِرَ السَّمَاوَاتِ وَاْلأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيْكَهُ، أَشْهَدُ أَنْ لاَ إِلَـهَ إِلاَّ أَنْتَ، أَعُوْذُ بِكَ مِنْ شَرِّ نَفْسِيْ، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِيْ سُوْءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
  ),
  DzikrItem(
    repetitions: 3,
    title: "Perlindungan dari Bahaya",
    arabicText: "بِسْمِ اللَّهِ الَّذِى لاَ يَضُرُّ مَعَ اسْمِهِ شَىْءٌ فِى الأَرْضِ وَلاَ فِى السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
  ),
  DzikrItem(
    repetitions: 3,
    title: "Pernyataan Ridha",
    arabicText: "رَضِيْتُ بِاللهِ رَبًّا، وَبِاْلإِسْلاَمِ دِيْنًا، وَبِمُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Permohonan Pertolongan",
    arabicText: "يَا حَيُّ يَا قَيُّوْمُ بِرَحْمَتِكَ أَسْتَغِيْثُ، وَأَصْلِحْ لِيْ شَأْنِيْ كُلَّهُ وَلاَ تَكِلْنِيْ إِلَى نَفْسِيْ طَرْفَةَ عَيْنٍ أَبَدًا",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Ikrar di Atas Fitrah Islam",
    arabicText: "أَصْبَحْنَا عَلَى فِطْرَةِ اْلإِسْلاَمِ وَعَلَى كَلِمَةِ اْلإِخْلاَصِ، وَعَلَى دِيْنِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِيْنَا إِبْرَاهِيْمَ، حَنِيْفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِيْنَ",
  ),
  DzikrItem(
    repetitions: 100,
    title: "Tasbih",
    arabicText: "سُبْحَانَ اللهِ وَبِحَمْدِهِ",
  ),
   DzikrItem(
    repetitions: 10,
    title: "Tahlil",
    arabicText: "لاَ إِلَـهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرُ",
  ),
  DzikrItem(
    repetitions: 100,
    title: "Tahlil (Versi 100x)",
    arabicText: "لاَ إِلَـهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرُ",
  ),
  DzikrItem(
    repetitions: 3,
    title: "Tasbih (Versi Lengkap)",
    arabicText: "سُبْحَانَ اللهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ",
  ),
   DzikrItem(
    repetitions: 1,
    title: "Doa Memohon Ilmu",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلاً مُتَقَبَّلاً",
  ),
  DzikrItem(
    repetitions: 100,
    title: "Istighfar",
    arabicText: "أَسْتَغْفِرُ اللهَ وَأَتُوْبُ إِلَيْهِ",
  ),
];

// ===== DZIKIR PETANG (LENGKAP: AL-QUR'AN & HADITS) =====
final List<DzikrItem> dzikirPetangLengkapList = [
  DzikrItem(
    repetitions: 1,
    title: "Ta'awudz",
    arabicText: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ",
  ),
  ...dzikirPetangList, // Mengambil semua dari list Al-Qur'an
  DzikrItem(
    repetitions: 1,
    title: "Doa Petang Hari",
    arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ للهِ، وَالْحَمْدُ للهِ، لَا إِلَهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُبِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُبِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُبِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ",
  ),
   DzikrItem(
    repetitions: 1,
    title: "Doa Pagi & Petang",
    arabicText: "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا،وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيْرُ",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Sayyidul Istighfar",
    arabicText: "اَللَّهُمَّ أَنْتَ رَبِّيْ لاَ إِلَـهَ إِلاَّ أَنْتَ، خَلَقْتَنِيْ وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوْذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوْءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوْءُ بِذَنْبِيْ فَاغْفِرْ لِيْ فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوْبَ إِلاَّ أَنْتَ.",
  ),
   DzikrItem(
    repetitions: 4,
    title: "Permohonan Pembebasan dari Neraka",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَمْسَيْتُ أُشْهِدُكَ وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتَكَ وَجَمِيْعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللهُ لاَ إِلَـهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيْكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُوْلُكَ",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Permohonan Keselamatan",
    arabicText: "اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَاْلآخِرَةِ، اَللَّهُمَّ إِنِّيْ أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِيْنِيْ وَدُنْيَايَ وَأَهْلِيْ وَمَالِيْ اللَّهُمَّ اسْتُرْ عَوْرَاتِى وَآمِنْ رَوْعَاتِى. اَللَّهُمَّ احْفَظْنِيْ مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِيْ، وَعَنْ يَمِيْنِيْ وَعَنْ شِمَالِيْ، وَمِنْ فَوْقِيْ، وَأَعُوْذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِيْ",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Doa Perlindungan",
    arabicText: "اَللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَadَةِ فَاطِرَ السَّمَاوَاتِ وَاْلأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيْكَهُ، أَشْهَدُ أَنْ لاَ إِلَـهَ إِلاَّ أَنْتَ، أَعُوْذُ بِكَ مِنْ شَرِّ نَفْسِيْ، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِيْ سُوْءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ",
  ),
  DzikrItem(
    repetitions: 3,
    title: "Perlindungan dari Bahaya",
    arabicText: "بِسْمِ اللَّهِ الَّذِى لاَ يَضُرُّ مَعَ اسْمِهِ شَىْءٌ فِى الأَرْضِ وَلاَ فِى السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
  ),
  DzikrItem(
    repetitions: 3,
    title: "Pernyataan Ridha",
    arabicText: "رَضِيْتُ بِاللهِ رَبًّا، وَبِاْلإِسْلاَمِ دِيْنًا، وَبِمُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا",
  ),
  DzikrItem(
    repetitions: 1,
    title: "Permohonan Pertolongan",
    arabicText: "يَا حَيُّ يَا قَيُّوْمُ بِرَحْمَتِكَ أَسْتَغِيْثُ، وَأَصْلِحْ لِيْ شَأْنِيْ كُلَّهُ وَلاَ تَكِلْنِيْ إِلَى نَفْسِيْ طَرْفَةَ عَيْنٍ أَبَدًا",
  ),
  DzikrItem(
    repetitions: 100,
    title: "Tasbih",
    arabicText: "سُبْحَانَ اللهِ وَبِحَمْدِهِ",
  ),
  DzikrItem(
    repetitions: 10,
    title: "Tahlil",
    arabicText: "لاَ إِلَـهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرُ",
  ),
  DzikrItem(
    repetitions: 3,
    title: "Perlindungan dari Kejahatan Makhluk",
    arabicText: "أَعُوْذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
  ),
];