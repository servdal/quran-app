# 🏆 Mushaf  
### Digital Qur’an & Islamic Companion

---

## 🇮🇩 Bahasa Indonesia

**Mushaf** adalah aplikasi **open-source** yang dirancang sebagai **pendamping ibadah digital** untuk membantu umat Muslim membaca, mempelajari, dan merenungi Al-Qur’an, sekaligus mendukung aktivitas ibadah harian dalam satu aplikasi terpadu.

Aplikasi ini dibangun menggunakan **Flutter** dan dirancang agar **intuitif, cepat, modern**, serta dapat digunakan lintas platform.

---

### 🆕 Apa yang Baru

- **Playlist tersimpan lebih sederhana**: tombol Play di kiri dan Hapus di kanan, tanpa menu titik tiga atau pilihan Play ganda.
- **Navigasi mini player**: tombol Previous dan Next untuk berpindah ke ayat sebelumnya atau berikutnya. Kontrol berada di baris bawah agar judul tetap terbaca pada layar kecil.
- **Perbaikan pemutaran otomatis**: memperbaiki audio yang berhenti setelah ayat pertama saat playlist pertama kali diputar, sehingga perpindahan ayat dan pengulangan playlist tidak perlu dipicu dengan menekan Next terlebih dahulu.

---

### ✨ Fitur Utama

#### 📖 Mode Membaca Al-Qur’an
- **Per Halaman** — Tampilan mushaf per halaman seperti Al-Qur’an cetak.
- **Per Surah** — Tampilan standar berbasis surah dan ayat.
- **Mode Klasik** — Nuansa mushaf klasik.
- **Mode Belajar** — Pembelajaran Tajwid dan Nahwu langsung pada ayat.

#### 🧾 Detail Ayat Lengkap (4 Tab)
- **Teks** — Teks Arab dengan **pewarnaan Tajwid** dan transliterasi Latin.  
- **Arti** — Terjemahan Bahasa Indonesia.  
- **Tafsir** — Tafsir **Jalalayn**  
- **Audio** — Audio oleh **KH. Bahauddin Nursalim (Gus Baha)**  


#### 🕌 Fitur Pendukung Ibadah
- **Jadwal Sholat & Countdown** berbasis lokasi.
- **Dzikir Pagi & Petang** bersumber dari Al-Qur’an.
- **Kumpulan Doa** tematik beserta adab berdoa.
- **Aqidatul Awam** (nadham aqidah).
- **Glosarium Tajwid** lengkap dengan contoh.

#### ⚙️ Personalisasi & Navigasi
- **Pencarian Cerdas** surah & ayat.
- **Bookmark Multi-Level**.
- **Pengaturan Ukuran Font Arab**.
- **Navigasi Cepat** antar ayat, halaman, dan surah.

#### 🔖 Fitur Tambahan
- Penanda **ayat sajdah**.
- **Berbagi ayat** (teks Arab, arti, dan tafsir).

---

### 🛠️ Teknologi
- **Framework**: Flutter  
- **State Management**: Riverpod  
- **Data Al-Qur’an & Tafsir**: Olahan dari berbagai sumber API  
- **Pewarnaan Tajwid**: Client-side parsing  
- **Jadwal Sholat**: Aladhan Prayer Times API  
- **Notifikasi**: flutter_local_notifications  

---

### 📚 Sumber Data & Referensi

Aplikasi Mushaf memanfaatkan dan mengolah data dari berbagai sumber terpercaya, antara lain:

1. **Kementerian Agama Republik Indonesia**  
   https://quran.kemenag.go.id/  
   (Font, Teks Arab dan Terjememah Indonesia)

2. **AlQuran Cloud API**  
   https://alquran.cloud/  
   (Referensi mushaf, terjemahan, dan struktur Al-Qur’an)

3. **Tafsir Jalalayn (English Translation)**  
   https://www.academia.edu/39891639/Al_Jalalain_Eng  

4. **Tafsir Jalalayn (PDF Indonesia)**  
   https://www.alkhoirot.org/2017/11/terjemah-kitab-tafsir-jalalain.html  

5. **Audio Murottal**  
   https://everyayah.com/  

6. **Inspirasi**  
   KH. Bahauddin Nursalim (Gus Baha)
   https://www.youtube.com/@officiallp3ia

7. **Sumber-sumber lain**  
   Beberapa data tambahan diperoleh dari referensi terbuka (open sources), literatur Islam, dan kontribusi komunitas yang belum seluruhnya tercatat secara eksplisit.  
   Apabila terdapat sumber yang terlewat, silakan menghubungi pengembang untuk penambahan atribusi yang sesuai.

---

### 🚀 Distribusi
- **Android**  
  https://play.google.com/store/apps/details?id=alquran.duidev.com  
- **iOS and MAC**  
  https://apps.apple.com/us/app/mushaf/id6799260550  
- **Web**  
  https://duidev-project.web.app  

---

### 📚 Database Hadist Offline

Fitur Hadist menyediakan enam koleksi Arab–Indonesia: Shahih Bukhari (7.008),
Shahih Muslim (5.362), Sunan Abu Daud (4.590), Sunan Ibnu Majah (4.332),
Sunan Nasa’i (5.662), dan Sunan Tirmidzi (3.891), total **30.845 entri**.
Pengguna dapat memilih kitab, mencari teks atau nomor, dan membaca hadis secara offline.

- **Sumber:** [irsyadulibad/hadits-database](https://github.com/irsyadulibad/hadits-database).
- **Revisi sumber:** `db43bdaa70ee528a0e663c089d3dab5bb4d855f0`.
- **Lisensi repository dataset:** MIT, Copyright (c) 2020 Ahmad Irsyadul Ibad.
  Salinan lengkap dipertahankan di `assets/database/HADITH_LICENSE.txt`.
- **Database hasil konversi:** `assets/database/hadith.db` (SQLite), terpisah dari Al-Qur’an.
- **Manifest:** `assets/database/hadith_manifest.json`, berisi jumlah entri dan SHA-256 file sumber.

Nomor hadis mengikuti dataset sumber, bukan pemetaan otomatis ke penomoran edisi lain.
Dataset dasar tidak menyediakan judul bab atau derajat hadis. Metadata tambahan
berasal dari [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api),
revisi `df57907be35291c91ad6a6691180e22ca9920784`, dengan lisensi repository
Unlicense (salinan di `assets/database/HADITH_ENRICHMENT_LICENSE.txt`).
Metadata penerjemah Indonesia di sumber tambahan tercatat sebagai `Unknown`;
teks Indonesia lokal tetap dipertahankan tanpa penggantian.

Pengayaan versi 2 mencocokkan **24.047** dari 30.845 entri berdasarkan kesamaan
seluruh teks Arab dan/atau Indonesia setelah normalisasi tanda baca, diakritik,
dan huruf besar. Nomor lokal tidak dipakai sebagai dasar pencocokan. Teks pendek,
nomor sumber duplikat, pasangan ambigu, penggunaan ulang pasangan sumber oleh
beberapa entri lokal, referensi antarbahasa yang berbeda, serta kecocokan Arab dan
Indonesia yang bertentangan ditolak. Ini pemetaan otomatis konservatif, bukan
klaim verifikasi ilmiah/manual seluruh riwayat.

- **24.020** entri memiliki terjemahan Inggris lokal dari sumber.
- **24.036** entri memiliki relasi bagian/bab, dalam **323** kelompok judul.
- **10** kelompok memiliki hadis dari lebih dari satu kitab.
- **14.354** entri memiliki penilaian, ditampilkan bersama nama penilainya.
- Entri lainnya tetap tersedia dengan teks asli; metadata yang belum cocok dibiarkan kosong.

Tab Bab dapat dicari dan dibuka lintas kitab. Tombol Pilih bab pada daftar kitab
membatasi bab dan hadis ke kitab tersebut. Pengelompokan hanya menyatukan judul
sumber yang sama setelah normalisasi; judul berbeda tidak dipaksakan menjadi tema
yang sama. Label Indonesia tersedia untuk sejumlah judul umum; lainnya menampilkan
judul sumber. Cakupan bab bersifat parsial dan dijelaskan di layar.

`hadith_enrichment_audit.json` menyimpan hash SHA-256 ke-18 file masukan, revisi,
metode pencocokan, cakupan per kitab, serta nomor lokal yang belum cocok.
Tabel `hadith_source_matches` menyimpan nomor sumber dan metode untuk setiap
pasangan; `source_reference` tidak menggantikan nomor lokal. Database runtime
memakai nama `hadith-v2.db`, sehingga pemasangan lama mendapatkan aset pengayaan.

Untuk membangun ulang, unduh repository sumber pada revisi di atas, lalu jalankan:

```sh
python3 tools/data/build_hadith_database.py /path/to/hadits-database
```

Lalu unduh 18 file `ara-`, `ind-`, dan `eng-` untuk Bukhari, Muslim, Abu Dawud,
Tirmidzi, Ibnu Majah, dan Nasa’i dari revisi pengayaan di atas. Simpan bersama
`LICENSE` dan `revision.txt` (berisi SHA revisi), kemudian jalankan:

```sh
python3 tools/data/enrich_hadith_database.py /path/to/pinned/editions
```

Konverter membaca nilai SQL sebagai data tanpa menjalankan dump, mempertahankan teks,
serta memvalidasi jumlah entri, urutan nomor, isian kosong, integritas SQLite, dan relasi.

---

### Kelengkapan data per kata Al-Qur’an

Aset `assets/database/quran.db` versi 4 memuat **77.429 posisi kata** dalam
`master_edited` untuk 6.236 ayat. Jumlah baris 77.430 karena dua analisis akar
asli pada 20:94:2 dipertahankan. Sebanyak 23.721 posisi ditambahkan dari
[UmmahAPI Word-by-Word](https://ummahapi.com/api/docs); seluruh `merged_aya`,
id lama dan variasi penulisan yang tidak rusak tetap dipertahankan.

RootWordId dan atribut akar dipakai kembali hanya melalui kecocokan lokal yang
konsisten. RootWordId tidak digunakan untuk menebak kelas nahwu atau arti konteks.
Kolom Indonesia/akar/nahwu yang belum mempunyai padanan tetap NULL. Sebanyak
53.878 baris lengkap seluruh isian dan 23.552 masih parsial; “lengkap” di sini
berarti kelengkapan field, bukan tinjauan linguistik manual.

Laporan tersedia di `reports/quran_master_completion/summary.md`, termasuk CSV
baris lengkap, baris parsial beserta kolom kosong, padanan RootWordId, perubahan,
dan rekap per surah. Provenance per perubahan tersimpan dalam tabel
`master_edited_completion_log`. Audit sebelum dan sesudah disimpan terpisah pada
`reports/quran_word_audit/` dan `reports/quran_word_audit_after_completion/`.
Cadangan sebelum perubahan tersimpan lokal di `backups/` dan diabaikan Git.

Untuk membangun ulang dari cadangan dan cache respons yang sama:

```sh
python3 tools/data/complete_quran_master.py --cache /tmp/quran-word-audit \
  --baseline backups/quran-before-master-completion-602bb0e5077e.db
```

Tutup dan buka kembali aplikasi setelah build baru agar salinan database lokal
memuat pembaruan versi 4.

---

### 📜 Lisensi
Mushaf adalah aplikasi **GRATIS & Open-Source**.  
Anda bebas menggunakan, memodifikasi, dan mendistribusikan ulang aplikasi ini untuk tujuan apa pun.

---

### ☕ Dukung Pengembangan
Jika Mushaf bermanfaat bagi Anda, silakan berdonasi untuk mendukung pengembangan selanjutnya.

<p align="center">
  <img src="https://masjidi.duidev.com/qrcodeduidev.png" alt="QRIS Donasi" width="300">
</p>

---

## 🇬🇧 English Version

**Mushaf** is an **open-source digital Islamic companion app** designed to help Muslims read, study, and reflect upon the Qur’an, while also supporting daily worship activities in a single, integrated application.

Built with **Flutter**, Mushaf delivers a **fast, intuitive, and modern** experience across multiple platforms.

---

### 🆕 What's New

- **Simpler saved playlists**: a Play button on the left and a Delete button on the right, without a three-dot menu or duplicate Play options.
- **Mini player navigation**: Previous and Next buttons to move between verses. Controls sit below the track information to keep the title readable on small screens.
- **Automatic playback fix**: fixed playback stopping after the first verse when starting a playlist for the first time, so verse transitions and playlist repeat no longer require pressing Next first.

---

### ✨ Key Features

#### 📖 Qur’an Reading Modes
- **Page View** — Mushaf-style page layout like the printed Qur’an.
- **Surah View** — Standard verse-by-verse reading.
- **Classic Mode** — Traditional mushaf appearance.
- **Learning Mode** — Tajweed and Nahwu learning directly on verses.

#### 🧾 Complete Ayah Details (4 Tabs)
- **Text** — Arabic text with **Tajweed color highlighting** and Latin transliteration.  
- **Translation** — Indonesian translation.  
- **Tafsir** — **Tafsir Jalalayn**  
- **Audio** — Audio by **KH. Bahauddin Nursalim (Gus Baha)**  

#### 🕌 Worship Companion Features
- **Prayer Times & Countdown** based on user location.
- **Morning & Evening Dhikr** sourced from the Qur’an.
- **Collection of Du’a** categorized by themes.
- **Aqidatul Awam** (Islamic creed poem).
- **Tajweed Glossary** with explanations and examples.

---

### 🛠️ Tech Stack
- **Framework**: Flutter  
- **State Management**: Riverpod  
- **Qur’an & Tafsir Data**: Processed from multiple API sources  
- **Tajweed Highlighting**: Client-side parsing  
- **Prayer Times**: Aladhan Prayer Times API  
- **Notifications**: flutter_local_notifications  

---

### 📚 Data Sources & References

Mushaf utilizes and processes data from several trusted sources, including:

1. **Ministry of Religious Affairs of the Republic of Indonesia**  
   https://quran.kemenag.go.id/

2. **AlQuran Cloud API**  
   https://alquran.cloud/

3. **Tafsir Jalalayn (English Translation)**  
   https://www.academia.edu/39891639/Al_Jalalain_Eng

4. **Inspiration**  
   KH. Bahauddin Nursalim (Gus Baha)  
   https://www.youtube.com/@officiallp3ia

5. **Other references**  
   Additional data are sourced from various open references, Islamic literature, and community contributions that may not yet be fully documented.  
   If any attribution is missing, please contact the developer for proper acknowledgment.

---

### 👨‍💻 Distribution
- **Android**  
  https://play.google.com/store/apps/details?id=alquran.duidev.com  
- **iOS and MAC**  
  https://apps.apple.com/us/app/mushaf/id6799260550  
- **Web**  
  https://duidev-project.web.app  

---

### 📜 License
Mushaf is **FREE & Open-Source** software.  
You are free to use, modify, and redistribute it for any purpose.

---

🙏  
May **Mushaf** become a source of benefit, guidance, and blessing for all.

### Tampilan dan informasi koleksi Hadist

Halaman koleksi menampilkan statistik dari database: jumlah hadis, ketersediaan
Inggris offline, penilaian, serta cakupan bab per kitab. Kartu daftar menampilkan
cuplikan Arab–terjemahan dan indikator metadata. Layout koleksi memakai dua kolom
pada layar lebar dan satu kolom di ponsel, mengikuti tema terang/gelap aplikasi.

Tombol **Informasi hadis** di detail membuka bab terkait (dapat dibuka lintas kitab),
nomor utama dan referensi tambahan yang dibedakan, serta penilaian dengan nama
penilainya. Metadata yang belum tersedia dijelaskan tanpa mengasumsikan status
hadis. Panel **Tentang koleksi** menjelaskan sumber, lisensi, pemetaan parsial,
perbedaan penomoran, dan bahasa yang dapat dibaca offline.

### Bookmark dan tampilan Hadist

- Ikon bookmark tersedia pada daftar dan detail hadis. Identitasnya adalah pasangan
  kitab dan nomor lokal; misalnya Bukhari nomor 1 berbeda dari Muslim nomor 1.
- Tab Bookmark menyediakan filter kitab dan membuka langsung hadis yang disimpan.
- Ikon **Tampilan teks** pada detail menyediakan mode tab, Arab saja, terjemah saja,
  atau Arab dan terjemah dalam satu halaman. Teks tetap dapat dipilih/disalin.
- Font Arab: LPMQ, KFGQPC, dan UthmanicHafs. Ukuran Arab 18–60 dan terjemah 12–32,
  dengan pratinjau sebelum menekan Terapkan.
- Bookmark dan pilihan tampilan disimpan di preferensi `hadith_reader_v1`, terpisah
  dari bookmark Al-Qur’an. Sebelum ukuran khusus dipilih, ukuran mengikuti setting
  Arab dan panel ayat aplikasi. Setelah diterapkan, setelan Hadist berlaku untuk
  seluruh kitab dan bertahan setelah aplikasi dibuka kembali.

### Bahasa dan terjemahan Hadist

Label layar mengikuti pengaturan bahasa aplikasi: Indonesia untuk `id`, Inggris
untuk pilihan lainnya, mengikuti pola layar Al-Qur’an. Detail Hadist memiliki tab
Teks Arab dan Terjemah; ukuran teks mengikuti pengaturan font Arab dan panel ayat.
Terjemahan Indonesia tersedia offline. Untuk bahasa lain, permintaan hanya dibuat
saat tab Terjemah dibuka dan hasil berhasil disimpan dalam cache sesi per hadis
serta bahasa. Pencarian lokal mencari teks Arab, Indonesia, Inggris yang tersedia, serta nomor lokal.
Bahasa Inggris mengutamakan teks sumber yang tersedia offline, lalu memakai backend
jika belum ada pasangan Inggris. Bahasa lain tetap memakai backend terjemahan.

Backend Laravel menyediakan endpoint hadis `/api/translate/hadiths`. Endpoint Al-Qur’an `/api/translate/ayahs`
tidak digunakan untuk hadis karena identitas dan cache ayat berbeda. Adapter hadis
memakai `https://duidev.com/api/translate/hadiths` secara default; alamat dapat diganti
dengan `HADITH_TRANSLATE_ENDPOINT` saat build. Kontrak request berikut (harus HTTPS; header `X-API-Key` memakai `CORE_TRANSLATE_API_KEY`
bila tersedia):

```json
{
  "source_lang": "id",
  "target_lang": "en",
  "items": [{
    "book_id": "bukhari",
    "hadith_number": 1,
    "translation": "Teks terjemahan Indonesia dari dataset"
  }]
}
```

Respons yang didukung berupa array, atau array dalam `data`, `items`, atau `results`,
dengan field `translation` atau `translated_translation`. Jika endpoint belum
dikonfigurasi atau permintaan gagal, tab secara eksplisit menampilkan terjemahan
Indonesia sebagai fallback. Source backend berada di `/Users/duidev/htdocs/duidev`, modul Core. Sebelum dipakai
di produksi, deploy perubahan backend dan jalankan migrasi
`2026_10_19_000001_create_core_hadith_translation_caches_table.php`. Tabel cache hadis
terpisah dari cache ayat; perubahan teks sumber menghasilkan cache baru. Endpoint
menerima satu hadis per request dan menerjemahkan Indonesia ke bahasa pilihan,
termasuk Inggris. Hasil gagal tidak disimpan; tombol Coba lagi dapat mengulang request.
Terjemahan tambahan merupakan hasil layanan mesin yang sama dengan fitur Al-Qur’an.

### Penanganan data kata yang belum tersedia

Aset Quran versi 5 mempertahankan nilai analisis yang belum diketahui sebagai `NULL`.
Layar tafsir dan popup menampilkan keterangan sesuai bahasa pengaturan saat arti,
akar kata, analisis atau tafsir kosong. Kata tanpa akar tidak ikut disorot sebagai
kelompok akar yang sama. Data `WordNo <= 0` tidak dimuat sebagai kata valid.
Perapian spasi dapat direproduksi dengan `python3 tools/data/tidy_quran_master.py`;
rincian dan cadangan tercatat di `reports/quran_master_completion/cleanup.json`.
