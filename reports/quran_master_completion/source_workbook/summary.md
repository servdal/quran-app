# Rekonsiliasi sumber Excel — 19 Oktober 2026

Sumber: `/Users/duidev/Documents/kreatif project/Alquran/Quran Data Sheet/master_filled.xlsx`, sheet `master_filled`, A1:L53925.

## Penanda data tidak valid

- 53.924 baris sumber: 151 baris WordNo = 0 dan 53.773 baris bernomor positif.
- WordNo = 0 berarti data ditandai salah oleh pemilik sumber. Baris ini tidak boleh dianggap posisi kata valid, dinomori otomatis, atau dijadikan donor analisis.
- Tidak ada dari 151 baris tersebut yang cocok dengan database sebelum pelengkapan ketika seluruh 11 kolom lainnya dibandingkan.
- Karena tidak ada kecocokan itu dalam database awal, tidak ada donor yang berasal dari baris bertanda tersebut berdasarkan pencocokan ini. Kesamaan RootWordId saja tidak berarti baris lain ikut tidak valid.
- Nomor baris Excel bukan id database. Workbook tidak memiliki kolom id. Pencocokan menggunakan isi kolom, bukan urutan baris.

## Perbandingan sumber bernomor positif

Database awal memiliki 53.709 baris. Setelah nilai angka dinormalisasi menjadi teks dan spasi tepi diabaikan:

- 53.681 baris sumber bernomor positif cocok seluruh 12 kolom dengan database awal, dengan memperhitungkan jumlah duplikat.
- 92 baris sumber tidak cocok persis: 69 memiliki posisi yang ada tetapi isi kolom berbeda; 23 memiliki posisi yang tidak ada di database awal. Jumlah ini menghitung baris sumber, bukan posisi unik.
- 28 baris database awal tidak memiliki padanan persis dalam sumber bernomor positif.

Perbedaan tidak selalu kesalahan Excel: misalnya MeaningEn kosong pada 2:3:1 sudah terisi di database. Ada juga teks Arab bersih di Excel tetapi rusak dalam database awal; perbaikan sebelumnya telah memakai referensi API. Sebagian baris tambahan Excel memiliki WordNo positif namun lokasi dan teks perlu ditinjau, misalnya kata خَيْرًا ditempatkan pada 2:19:1. Karena itu WordNo positif bukan jaminan kebenaran semantik dan sumber tidak diimpor ulang secara menyeluruh.

## Berkas pemeriksaan

- `wordno_zero_review.csv`: 151 baris bertanda, nomor baris Excel dan hasil pencocokan database awal.
- `positive_source_differences.csv`: 92 baris sumber berbeda, dengan nilai sumber dan kandidat database pada posisi yang sama.
- `reconciliation.json`: angka rekonsiliasi, hash sumber dan definisi pencocokan.

Excel dan database tidak diubah dalam pemeriksaan ini. Laporan pelengkapan sebelumnya tetap menghitung kelengkapan kolom, bukan validasi linguistik seluruh isi.
