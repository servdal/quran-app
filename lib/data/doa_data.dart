// lib/data/doa_data.dart

// Model untuk setiap item doa
class DoaItem {
  final String title;
  final String source;
  final int surahId;
  final List<int> ayahs; // Diubah dari satu angka menjadi List

  DoaItem({
    required this.title,
    required this.source,
    required this.surahId,
    required this.ayahs,
  });
}

// Model untuk setiap poin adab
class AdabItem {
  final String title;
  final String description;

  AdabItem({required this.title, required this.description});
}

// --- Daftar Doa dari Al-Quran (Struktur Baru) ---
final List<DoaItem> daftarDoaAlQuran = [
  DoaItem(title: "Doa Sapu Jagat (Kebaikan Dunia & Akhirat)", source: "QS. Al-Baqarah: 201", surahId: 2, ayahs: [201]),
  DoaItem(title: "Doa untuk Bangsa dan Negara", source: "QS. Al-Baqarah: 126", surahId: 2, ayahs: [126]),
  DoaItem(title: "Doa Agar Dihindarkan dari Beban Berat", source: "QS. Al-Baqarah: 286", surahId: 2, ayahs: [286]),
  DoaItem(title: "Doa Dihindarkan dari Kesesatan", source: "QS. Ali Imran: 8-9", surahId: 3, ayahs: [8, 9]),
  DoaItem(title: "Doa Teguh Pendirian dan Pertolongan", source: "QS. Ali Imran: 147", surahId: 3, ayahs: [147]),
  DoaItem(title: "Doa Menghilangkan Rasa Takut", source: "QS. Ali Imran: 173", surahId: 3, ayahs: [173]),
  DoaItem(title: "Doa Mohon Rezeki", source: "QS. Al-Ma'idah: 114", surahId: 5, ayahs: [114]),
  DoaItem(title: "Doa Ketika Menghadapi Kecurangan", source: "QS. Al-A'raf: 89", surahId: 7, ayahs: [89]),
  DoaItem(title: "Doa Mohon Kesabaran dan Husnul Khatimah", source: "QS. Al-A'raf: 126", surahId: 7, ayahs: [126]),
  DoaItem(title: "Doa Penyerahan Diri (Tawakal)", source: "QS. At-Taubah: 129", surahId: 9, ayahs: [129]),
  DoaItem(title: "Doa Naik Kendaraan", source: "QS. Hud: 41", surahId: 11, ayahs: [41]),
  DoaItem(title: "Doa Berlindung dari Ajakan Orang Jahat", source: "QS. Yusuf: 33", surahId: 12, ayahs: [33]),
  DoaItem(title: "Doa Mohon Husnul Khatimah", source: "QS. Yusuf: 101", surahId: 12, ayahs: [101]),
  DoaItem(title: "Doa Mohon Perlindungan", source: "QS. Ibrahim: 37", surahId: 14, ayahs: [37]),
  DoaItem(title: "Doa Saat Pindah Tempat Tinggal", source: "QS. Al-Isra: 80", surahId: 17, ayahs: [80]),
  DoaItem(title: "Doa Memohon Rahmat dan Petunjuk", source: "QS. Al-Kahfi: 10", surahId: 18, ayahs: [10]),
  DoaItem(title: "Doa Mohon Kelapangan dan Kelancaran", source: "QS. Taha: 25-27", surahId: 20, ayahs: [25, 26, 27]),
  DoaItem(title: "Doa Mohon Kesembuhan", source: "QS. Al-Anbiya: 83", surahId: 21, ayahs: [83]),
  DoaItem(title: "Doa Tauhid dan Penyesalan (Nabi Yunus)", source: "QS. Al-Anbiya: 87", surahId: 21, ayahs: [87]),
  DoaItem(title: "Doa Ketika Selamat dari Kezaliman", source: "QS. Al-Mu'minun: 28", surahId: 23, ayahs: [28]),
  DoaItem(title: "Doa Saat Menempati Tempat Baru", source: "QS. Al-Mu'minun: 29", surahId: 23, ayahs: [29]),
  DoaItem(title: "Doa Berlindung dari Sifat Zalim", source: "QS. Al-Mu'minun: 94", surahId: 23, ayahs: [94]),
  DoaItem(title: "Doa Mohon Perlindungan dari Setan", source: "QS. Al-Mu'minun: 97-98", surahId: 23, ayahs: [97, 98]),
  DoaItem(title: "Doa Mohon Keselamatan Keluarga", source: "QS. Asy-Syu'ara: 169", surahId: 26, ayahs: [169]),
  DoaItem(title: "Doa Istiqamah Bersyukur", source: "QS. An-Naml: 19", surahId: 27, ayahs: [19]),
  DoaItem(title: "Doa Mohon Kekayaan (Nabi Sulaiman)", source: "QS. Sad: 35", surahId: 38, ayahs: [35]),
  DoaItem(title: "Doa Mensyukuri Nikmat", source: "QS. Al-Ahqaf: 15", surahId: 46, ayahs: [15]),
  DoaItem(title: "Doa Sebelum Meninggalkan Majelis", source: "QS. As-Saffat: 180-182", surahId: 37, ayahs: [180, 181, 182]),
];


// --- Daftar Adab Berdoa (Tetap Sama) ---
final List<AdabItem> daftarAdabBerdoa = [
  AdabItem(title: "Ikhlas karena Allah", description: "Niatkan doa semata-mata hanya untuk Allah, bukan untuk tujuan duniawi atau pamer."),
  AdabItem(title: "Memulai dengan Pujian dan Shalawat", description: "Awali doa dengan memuji Allah (misalnya dengan Asmaul Husna) dan bershalawat kepada Nabi Muhammad ﷺ."),
  AdabItem(title: "Mengangkat Kedua Tangan", description: "Mengangkat kedua tangan saat berdoa adalah sunnah yang menunjukkan kerendahan hati dan kebutuhan seorang hamba."),
  AdabItem(title: "Menghadap Kiblat", description: "Sebisa mungkin, arahkan diri menghadap kiblat saat berdoa, karena ini adalah arah yang paling mulia."),
  AdabItem(title: "Yakin Akan Dikabulkan", description: "Berdoalah dengan penuh keyakinan dan harapan bahwa Allah akan mengabulkan, serta jangan tergesa-gesa meminta hasilnya."),
  AdabItem(title: "Merendahkan Suara", description: "Berdoalah dengan suara yang lirih dan lembut, antara berbisik dan berbicara keras, sebagai bentuk kekhusyuan."),
];