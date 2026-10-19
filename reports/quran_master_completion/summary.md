# Hasil pelengkapan master_edited — 19 Oktober 2026

## Hasil utama

Database hasil: `assets/database/quran.db` (versi aset 4).
Cadangan sebelum perubahan: `backups/quran-before-master-completion-602bb0e5077e.db`.
Isi seluruh tabel `merged_aya` dipastikan tetap sama.

| Pemeriksaan | Sebelum | Sesudah |
|---|---:|---:|
| Baris master_edited | 53,709 | 77,430 |
| Posisi kata unik | 53,708 | 77,429 |
| Posisi kata belum ada dibanding API | 23,721 | **0** |
| Ayat yang memiliki kata | 6,214 | **6,236** |
| WordAr kosong | 1 | **0** |
| WordAr mengandung karakter rusak `??` | 17 | **0** |

Jumlah baris akhir lebih banyak satu dari posisi kata karena dua analisis akar
asli untuk 20:94:2 tetap dipertahankan (id 8178 dan 13219). Ini bukan posisi kata
tambahan. Id lama tidak diubah dan id baru dimulai setelah id maksimum lama 53924.
Posisi 2:5 sekarang berisi WordNo 1–8.

## Mana yang sudah lengkap dan belum

“Lengkap” di laporan ini berarti semua isian WordAr, MeaningEn, MeaningId,
RootWordId, RootAr, RootCode, RootEn, GrammarFormDesc, dan GrammarFormDescID terisi
serta tidak mengandung pola kerusakan yang diperiksa. Ini **bukan** sertifikasi
kebenaran linguistik atau tinjauan manual seluruh terjemahan.

| Status | Baris |
|---|---:|
| Lengkap seluruh isian | **53,878** |
| Masih parsial | **23,552** |
| Posisi baru yang menjadi lengkap seluruh isian | 169 |
| Posisi baru dengan sebagian analisis lokal berhasil diwariskan | 71 |
| Posisi baru yang belum memiliki padanan analisis lokal | 23,481 |

Semua posisi memiliki teks Arab dan arti Inggris. Data yang belum dipastikan tetap
NULL; tidak diisi akar, kelas nahwu, atau terjemahan Indonesia buatan.

### Isian yang masih belum tersedia

| Isian | Baris belum lengkap |
|---|---:|
| RootWordId dan masing-masing RootAr / RootCode / RootEn | 23,531 |
| MeaningId | 23,500 |
| Masing-masing GrammarFormDesc / GrammarFormDescID | 23,533 |

Jumlah per isian saling tumpang tindih, jadi tidak boleh dijumlahkan menjadi jumlah
baris unik. Akar kata tidak selalu berlaku untuk semua jenis kata; NULL pada
partikel/kata ganti juga tidak selalu berarti ada akar yang seharusnya ditebak.

## Cara RootWordId digunakan

1. Posisi baru diambil dari `position` bertipe `word`, bukan pemisahan spasi atau
   tanda waqaf.
2. Teks Arab ternormalisasi dan arti Inggris harus cocok dengan baris lokal.
   RootWordId hanya diwariskan jika semua kandidat mengarah pada satu id.
3. Alternatif terbatas: bentuk Arab bervokal sama, berulang pada sedikitnya dua
   ayat, dengan atribut akar/nahwu yang konsisten. Arti Indonesia tidak diwariskan
   melalui alternatif ini karena konteks arti Inggris dapat berbeda.
4. Setelah RootWordId teridentifikasi, RootAr, RootCode, dan RootEn dilengkapi dari
   nilai bersih yang disepakati kelompok id tersebut. **190** baris baru memakai
   RootWordId lama, mencakup **7** id berbeda; tidak ada id akar baru yang diciptakan.
5. GrammarFormDesc/ID tetap harus konsisten pada kandidat bentuk kata, bukan
   disalin hanya karena memiliki akar sama. Dua bentuk dari satu akar dapat
   memiliki klasifikasi gramatikal berbeda.
6. Arti Indonesia hanya diwariskan dari kecocokan kata+arti Inggris yang memiliki
   satu terjemahan lokal konsisten (perbedaan kapitalisasi diabaikan).
7. Hanya baris asli dipakai sebagai donor. Hasil pelengkapan tidak dipakai kembali
   sebagai donor untuk menghindari rangkaian asumsi.

Dari kata baru: 230 memiliki kandidat kata+arti Inggris, 10 memakai konsensus bentuk
bervokal, dan 23.481 hanya memiliki data dasar API. Kandidat dengan konflik antar
RootWordId, terjemahan, atau kelas kata tidak dipaksakan.

## Perbaikan baris lama

- 1 WordAr kosong pada 48:29:54 dipulihkan menjadi عَظِيمًۢا.
- 17 WordAr berisi `??` dipulihkan dari API pada posisi sama, dengan arti Inggris
  yang cocok. Variasi rasm/penulisan lain tidak ditimpa.
- 8 label akar rusak pada 7 kelompok RootWordId dipulihkan: 3 RootAr dan 5 RootEn.
- Total **26 baris lama diperbaiki**. Nilai sebelum perubahan dicatat.
- Dua akar pada 20:94:2 tetap ada; terjemahan Indonesia lama yang mencurigakan pada
  posisi itu tidak dikoreksi otomatis. Pelengkapan isian tidak mencakup revisi
  semantik terjemahan lama.

## Provenance dan berkas laporan

- `complete_rows.csv`: semua baris dengan isian lengkap, termasuk penanda asal lama/baru.
- `partial_rows.csv`: baris parsial beserta daftar tepat kolom yang masih kosong.
- `unmatched_analysis_rows.csv`: posisi baru yang baru memiliki teks Arab dan arti Inggris.
- `root_word_id_reuse.csv`: kamus nilai akar yang konsisten dan jumlah pemakaian lama/baru per id.
- `surah_summary.csv`: rekap lengkap/parsial/baru per surah (jumlah baris analisis).
- `changes.csv`: seluruh penambahan/perbaikan, nilai lama, isian baru dan id donor.
- `completion.json`: hitungan, definisi kelengkapan, hash database dan 114 respons sumber.
- Tabel `master_edited_completion_log`: log di dalam SQLite, termasuk id baris, metode,
  URL sumber, hash respons, transliterasi dari API dan waktu pelengkapan.

Sumber kata: https://ummahapi.com/api/quran/words/{surah}
Respons yang dipakai sudah diaudit sebelumnya dan disimpan di `/tmp/quran-word-audit`.
Laporan audit sebelum dan sesudah tersimpan terpisah pada
`reports/quran_word_audit` dan `reports/quran_word_audit_after_completion`.

## Validasi dan penggunaan aplikasi

Integritas SQLite dan foreign key lolos; semua posisi referensi kini ada; seluruh
baris/id lama dipertahankan; perubahan baris lama dibatasi pada field yang dicatat;
isi `merged_aya` diverifikasi dengan hash sebelum/sesudah.

`DBHelper` dinaikkan ke versi 4 agar aplikasi menyalin ulang aset baru untuk instalasi
lama. Tutup dan buka kembali aplikasi setelah build baru; hot reload saja tidak
mengganti database yang sudah terbuka. Bookmark/pengaturan berada di preferensi
terpisah.

Untuk membangun ulang secara atomik dari cadangan yang sama:

```sh
python3 tools/data/complete_quran_master.py --cache /tmp/quran-word-audit \
  --baseline backups/quran-before-master-completion-602bb0e5077e.db
```

Cadangan `.db` di `backups/` sengaja diabaikan Git, tetapi tetap tersimpan lokal.

## Pemeriksaan sumber Excel asli

Sumber `master_filled.xlsx` memiliki 151 baris bertanda WordNo = 0 yang menurut pemilik data belum valid. Pencocokan seluruh kolom lainnya tidak menemukan baris tersebut dalam database awal maupun donor pelengkapan. Ada 92 baris sumber bernomor positif yang tidak cocok persis dengan database awal dan perlu ditinjau sebelum impor ulang. Rincian: `source_workbook/summary.md`.

## Perapian dan penanganan data kosong (versi aset 5)

Sebanyak 523 field MeaningEn dibersihkan dari spasi tepi. Jumlah baris tetap 77.430 dan posisi unik tetap 77.429. Kolom analisis yang belum diketahui tetap NULL. Tidak ada WordNo <= 0 dalam aset. Perubahan dicatat dalam tabel master_edited_cleanup_log dan cleanup.json, dengan cadangan baru sebelum perapian.

Layar tafsir dan popup kini menampilkan keterangan saat tafsir, arti, akar, atau analisis belum tersedia. Kelompok akar hanya dihitung jika RootWordId positif dan RootAr tersedia. Filter tanpa hasil menampilkan keterangan. Nomor referensi ayat memakai surahId. Model menerima NULL serta angka tersimpan sebagai teks. Query mengabaikan WordNo <= 0.

Versi aset terbaru adalah 5. Setelah menjalankan ulang pelengkapan versi 4, jalankan `python3 tools/data/tidy_quran_master.py` untuk menghasilkan aset versi 5. Tutup dan buka ulang aplikasi agar salinan aset diperbarui.
