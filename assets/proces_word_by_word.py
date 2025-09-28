import os
import json

# Konfigurasi
# Pastikan skrip ini berada di direktori yang sama dengan folder 'surah' Anda
SUMBER_FOLDER = 'surah' 

def process_all_surahs_for_word_by_word():
    """
    Membaca semua file surah, memecah setiap ayat menjadi kata-kata,
    dan menambahkan struktur 'words' ke setiap objek ayat.
    """
    print("Memulai proses penambahan struktur arti per kata...")

    # Loop dari surah 1 hingga 114
    for surah_id in range(1, 115):
        file_name = os.path.join(SUMBER_FOLDER, f"{surah_id}.json")
        
        if not os.path.exists(file_name):
            print(f"Peringatan: File {file_name} tidak ditemukan, dilewati.")
            continue

        try:
            with open(file_name, 'r', encoding='utf-8') as f:
                surah_content = json.load(f)

            print(f"Memproses {file_name}...")

            # Iterasi melalui setiap ayat dalam data surah
            for verse in surah_content.get('data', []):
                # Lewati ayat jika sudah memiliki data 'words' untuk menghindari duplikasi
                if 'words' in verse and verse['words']:
                    continue

                aya_text = verse.get('aya_text', '')
                
                # Memecah teks Arab berdasarkan spasi. 
                # Ini adalah pendekatan sederhana dan titik awal yang baik.
                arabic_words = aya_text.split(' ')
                
                word_list = []
                for index, word in enumerate(arabic_words):
                    if word: # Pastikan kata tidak kosong
                        word_entry = {
                            "position": index + 1,
                            "arabic": word,
                            "transliteration": "", # Placeholder untuk Anda isi
                            "translation": ""      # Placeholder untuk Anda isi
                        }
                        word_list.append(word_entry)
                
                # Tambahkan list kata-kata ke objek ayat
                verse['words'] = word_list

            # Tulis kembali data yang sudah dimodifikasi ke file yang sama
            with open(file_name, 'w', encoding='utf-8') as f:
                json.dump(surah_content, f, ensure_ascii=False, indent=4)

        except Exception as e:
            print(f"Gagal memproses {file_name}: {e}")
            
    print("\nProses selesai!")
    print("Semua file surah sekarang memiliki struktur 'words' untuk diisi.")

if __name__ == "__main__":
    process_all_surahs_for_word_by_word()