# Audit kelengkapan master_edited

Database: `assets/database/quran.db`. Dibandingkan dengan 114 respons
`https://ummahapi.com/api/quran/words/{surah}` pada 19 Oktober 2026.
Database dibuka hanya-baca dan tidak diubah. Respons referensi disimpan sementara
pada `/tmp/quran-word-audit`; hash setiap respons ada di `audit.json`.

## Hasil seluruh Al-Qur’an

| Pemeriksaan | Jumlah |
|---|---:|
| Baris lokal master_edited | 53,709 |
| Posisi kata lokal unik | 53,708 |
| Posisi kata referensi API | 77,429 |
| Posisi belum tersimpan | 23,721 |
| Ayat dengan posisi belum tersimpan | 5,717 |
| Ayat tanpa baris lokal | 22 |
| Posisi dengan beberapa baris | 1 |
| Baris WordAr kosong | 1 |
| Posisi lokal di luar rentang referensi | 0 |
| Kandidat perbedaan teks setelah normalisasi dasar | 3,576 |

Cakupan posisi lokal: 69.36%.
Posisi yang belum tersimpan di awal ayat: 3,372; di antara posisi
yang tersimpan: 20,253; di akhir ayat: 71;
dalam ayat yang seluruhnya belum tersimpan: 25.

Angka 23.625 dari pemeriksaan internal awal hanya menghitung celah sebelum posisi
terakhir yang tersimpan. Perbandingan API diperlukan untuk menghitung ayat kosong
dan kata di akhir ayat; total akhirnya adalah 23.721.

## Contoh 2:5

| WordNo | API | Lokal |
|---|---|---|
| 1 | أُو۟لَـٰٓئِكَ | Belum tersimpan |
| 2 | عَلَىٰ | Belum tersimpan |
| 3 | هُدًى | Ada |
| 4 | مِن | Belum tersimpan |
| 5 | رَبِّهِمْ | Ada |
| 6 | وَأُو۟لَـٰٓئِكَ | Belum tersimpan |
| 7 | هُمُ | Belum tersimpan |
| 8 | ٱلْمُفْلِحُونَ | Ada |

## Temuan yang memerlukan perlakuan berbeda

1. **Data kemungkinan merupakan subset analisis akar kata.** Semua baris lokal
   memiliki RootAr; kata ganti, partikel dan huruf muqatta’ah banyak tidak ada.
   Ini inferensi dari pola data, bukan konfirmasi asal proses impor. Contoh 1:5
   hanya memuat dua verba, tanpa إِيَّاكَ dan وَإِيَّاكَ.
2. **Satu posisi dengan dua akar, bukan otomatis duplikat salah:** 20:94:2,
   id 8178 dan 13219, kata يَبۡنَؤُمَّ; akar ا م م dan ب ن ي. Pertahankan
   analisis tersebut sampai sumber morfologinya diverifikasi. MeaningId kedua
   baris adalah “di atas”, sedangkan MeaningEn “O son of my mother”; perlu tinjauan
   kualitas terjemahan yang terpisah.
3. **Satu WordAr kosong:** 48:29:54, id 35711, MeaningEn “great”, RootAr ع ظ م.
   Referensi API pada posisi tersebut adalah عَظِيمًۢا.
4. **Perbedaan teks bukan otomatis salah posisi:** dari 3.576 kandidat perbedaan,
   3,549 mempunyai arti Inggris yang sama persis setelah trim/casefold.
   Contoh صِرَاطَ vs صِرَٰطَ menunjukkan perbedaan rasm/alif kecil. Teks lokal juga
   memakai karakter bentuk lain, tanda waqaf, dan private-use glyph. Jangan menimpa
   semua 3.576 kandidat secara otomatis.
5. **Pemisahan spasi bukan WordNo:** `merged_aya.arabic_words` untuk 2:5 memuat
   sembilan token karena ada tanda waqaf terpisah, sementara API mempunyai delapan
   kata. Gunakan `position` dan `type=word`, bukan indeks array atau split spasi.

## Cakupan data API

API dapat menyediakan ChapterNo, VerseNo, WordNo, WordAr, MeaningEn dan transliterasi.
Respons ini tidak menyediakan MeaningId, RootAr/RootCode/RootEn/RootWordId,
GrammarFormDesc atau GrammarFormDescID. Transliterasi bukan kode akar kata;
`type=word` bukan jenis nahwu (isim/fi‘il/harf).

API cukup untuk melengkapi korpus kata dan arti Inggris, tetapi tidak cukup untuk
melengkapi seluruh analisis nahwu atau terjemahan Indonesia.

## Saran perbaikan

- Buat tabel kanonis `quran_words` dengan satu baris untuk setiap posisi kata;
  simpan teks Arab, arti Inggris, transliterasi dan provenance sumber.
- Pertahankan master_edited sebagai data akar/nahwu yang berelasi satu-ke-banyak
  ke posisi kata. Jangan pasang unique index pada master_edited sebelum menangani
  kasus beberapa akar per kata.
- Pada layar pembelajaran, baca daftar kata lengkap lalu gabungkan analisis lokal
  jika tersedia. Kolom yang belum tersedia ditampilkan sebagai belum ada data.
- Jika harus melengkapi master_edited langsung: hanya tambahkan posisi yang belum
  ada, isi kolom yang memang disediakan API, dan biarkan akar/nahwu/Indonesia NULL;
  pertahankan seluruh baris dan id lama. Buat backup dan provenance lebih dahulu.
- Jangan menyalin klasifikasi/akar dari kata lain berdasarkan kemiripan atau
  menganggap terjemahan mesin sebagai terjemahan per kata yang sudah diverifikasi.

## Berkas pemeriksaan

- `audit.json`: ringkasan lengkap dan hash respons referensi.
- `missing_words.csv`: seluruh 23.721 posisi belum tersimpan beserta teks referensi.
- `text_differences.csv`: kandidat perbedaan teks untuk tinjauan manual.
- `duplicate_positions.csv`: baris-baris pada posisi dengan beberapa akar.
- `outside_reference.csv`: kosong selain header karena semua posisi lokal berada
  dalam rentang referensi.

Ulangi audit tanpa memodifikasi database:

```sh
python3 tools/data/audit_quran_words.py --cache /tmp/quran-word-audit
```
