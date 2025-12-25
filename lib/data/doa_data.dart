// lib/data/doa_data.dart

// Model untuk setiap item doa
class DoaItem {
  final String titleId;
  final String titleEn;
  final String source;
  final int surahId;
  final List<int> ayahs;

  DoaItem({
    required this.titleId,
    required this.titleEn,
    required this.source,
    required this.surahId,
    required this.ayahs,
  });

  // Fungsi pembantu untuk UI
  String getTitle(String langCode) {
    return langCode == 'en' ? titleEn : titleId;
  }
}

// Model untuk setiap poin adab
class AdabItem {
  final String titleId;
  final String titleEn;
  final String descriptionId;
  final String descriptionEn;

  AdabItem({
    required this.titleId,
    required this.titleEn,
    required this.descriptionId,
    required this.descriptionEn,
  });

  String getTitle(String langCode) => langCode == 'en' ? titleEn : titleId;
  String getDescription(String langCode) => langCode == 'en' ? descriptionEn : descriptionId;
}

// --- Daftar Doa dari Al-Quran (Bilingual) ---
final List<DoaItem> daftarDoaAlQuran = [
  DoaItem(
    titleId: "Doa Sapu Jagat (Kebaikan Dunia & Akhirat)", 
    titleEn: "The Comprehensive Prayer (Goodness in Life & Hereafter)",
    source: "QS. Al-Baqarah: 201", surahId: 2, ayahs: [201]
  ),
  DoaItem(
    titleId: "Doa untuk Bangsa dan Negara", 
    titleEn: "Prayer for the Nation and Country",
    source: "QS. Al-Baqarah: 126", surahId: 2, ayahs: [126]
  ),
  DoaItem(
    titleId: "Doa Agar Dihindarkan dari Beban Berat", 
    titleEn: "Prayer to be Relieved from Heavy Burdens",
    source: "QS. Al-Baqarah: 286", surahId: 2, ayahs: [286]
  ),
  DoaItem(
    titleId: "Doa Dihindarkan dari Kesesatan", 
    titleEn: "Prayer for Protection from Misguidance",
    source: "QS. Ali Imran: 8-9", surahId: 3, ayahs: [8, 9]
  ),
  DoaItem(
    titleId: "Doa Teguh Pendirian dan Pertolongan", 
    titleEn: "Prayer for Firmness and Assistance",
    source: "QS. Ali Imran: 147", surahId: 3, ayahs: [147]
  ),
  DoaItem(
    titleId: "Doa Menghilangkan Rasa Takut", 
    titleEn: "Prayer to Remove Fear",
    source: "QS. Ali Imran: 173", surahId: 3, ayahs: [173]
  ),
  DoaItem(
    titleId: "Doa Mohon Rezeki", 
    titleEn: "Prayer for Sustenance (Rizq)",
    source: "QS. Al-Ma'idah: 114", surahId: 5, ayahs: [114]
  ),
  DoaItem(
    titleId: "Doa Ketika Menghadapi Kecurangan", 
    titleEn: "Prayer When Facing Deception",
    source: "QS. Al-A'raf: 89", surahId: 7, ayahs: [89]
  ),
  DoaItem(
    titleId: "Doa Mohon Kesabaran dan Husnul Khatimah", 
    titleEn: "Prayer for Patience and a Good Ending",
    source: "QS. Al-A'raf: 126", surahId: 7, ayahs: [126]
  ),
  DoaItem(
    titleId: "Doa Penyerahan Diri (Tawakal)", 
    titleEn: "Prayer of Absolute Trust (Tawakkul)",
    source: "QS. At-Taubah: 129", surahId: 9, ayahs: [129]
  ),
  DoaItem(
    titleId: "Doa Naik Kendaraan", 
    titleEn: "Prayer for Traveling/Mounting a Vehicle",
    source: "QS. Hud: 41", surahId: 11, ayahs: [41]
  ),
  DoaItem(
    titleId: "Doa Berlindung dari Ajakan Orang Jahat", 
    titleEn: "Prayer to be Protected from Evil Influences",
    source: "QS. Yusuf: 33", surahId: 12, ayahs: [33]
  ),
  DoaItem(
    titleId: "Doa Mohon Husnul Khatimah", 
    titleEn: "Prayer for a Good Conclusion (Death)",
    source: "QS. Yusuf: 101", surahId: 12, ayahs: [101]
  ),
  DoaItem(
    titleId: "Doa Memohon Rahmat dan Petunjuk", 
    titleEn: "Prayer for Mercy and Guidance",
    source: "QS. Al-Kahfi: 10", surahId: 18, ayahs: [10]
  ),
  DoaItem(
    titleId: "Doa Mohon Kelapangan dan Kelancaran", 
    titleEn: "Prayer for Ease and Clear Speech (Musa's Prayer)",
    source: "QS. Taha: 25-27", surahId: 20, ayahs: [25, 26, 27]
  ),
  DoaItem(
    titleId: "Doa Mohon Kesembuhan", 
    titleEn: "Prayer for Healing (Ayub's Prayer)",
    source: "QS. Al-Anbiya: 83", surahId: 21, ayahs: [83]
  ),
  DoaItem(
    titleId: "Doa Tauhid dan Penyesalan (Nabi Yunus)", 
    titleEn: "Prayer of Repentance and Monotheism",
    source: "QS. Al-Anbiya: 87", surahId: 21, ayahs: [87]
  ),
  DoaItem(
    titleId: "Doa Saat Menempati Tempat Baru", 
    titleEn: "Prayer for Settling in a New Place",
    source: "QS. Al-Mu'minun: 29", surahId: 23, ayahs: [29]
  ),
  DoaItem(
    titleId: "Doa Mohon Perlindungan dari Setan", 
    titleEn: "Prayer for Protection from Satanic Whispers",
    source: "QS. Al-Mu'minun: 97-98", surahId: 23, ayahs: [97, 98]
  ),
];

// --- Daftar Adab Berdoa (Bilingual) ---
final List<AdabItem> daftarAdabBerdoa = [
  AdabItem(
    titleId: "Ikhlas karena Allah", 
    titleEn: "Sincerity for Allah",
    descriptionId: "Niatkan doa semata-mata hanya untuk Allah, bukan untuk tujuan duniawi atau pamer.",
    descriptionEn: "Intend your prayer solely for the sake of Allah, not for worldly goals or showing off."
  ),
  AdabItem(
    titleId: "Memulai dengan Pujian dan Shalawat", 
    titleEn: "Starting with Praises and Blessings",
    descriptionId: "Awali doa dengan memuji Allah (misalnya dengan Asmaul Husna) dan bershalawat kepada Nabi Muhammad ﷺ.",
    descriptionEn: "Begin the prayer by praising Allah (e.g., using Asmaul Husna) and sending blessings upon Prophet Muhammad ﷺ."
  ),
  AdabItem(
    titleId: "Mengangkat Kedua Tangan", 
    titleEn: "Raising Both Hands",
    descriptionId: "Mengangkat kedua tangan saat berdoa adalah sunnah yang menunjukkan kerendahan hati.",
    descriptionEn: "Raising both hands during prayer is a Sunnah that shows humility and the need of a servant."
  ),
  AdabItem(
    titleId: "Menghadap Kiblat", 
    titleEn: "Facing the Qiblah",
    descriptionId: "Sebisa mungkin, arahkan diri menghadap kiblat saat berdoa.",
    descriptionEn: "Whenever possible, face the Qiblah while praying, as it is the most noble direction."
  ),
  AdabItem(
    titleId: "Yakin Akan Dikabulkan", 
    titleEn: "Certainty of Acceptance",
    descriptionId: "Berdoalah dengan penuh keyakinan dan harapan bahwa Allah akan mengabulkan.",
    descriptionEn: "Pray with full conviction and hope that Allah will answer, and do not be hasty."
  ),
  AdabItem(
    titleId: "Merendahkan Suara", 
    titleEn: "Lowering the Voice",
    descriptionId: "Berdoalah dengan suara yang lirih dan lembut sebagai bentuk kekhusyuan.",
    descriptionEn: "Pray with a low and gentle voice as a form of devotion and humility."
  ),
];