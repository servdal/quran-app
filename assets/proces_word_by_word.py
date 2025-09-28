import os
import json
import pyarabic.araby as araby
from tashaphyne.stemming import ArabicLightStemmer

# Konfigurasi
# Pastikan skrip ini berada di direktori yang sama dengan folder 'surah' Anda
SUMBER_FOLDER = 'surah' 

def process_all_surahs_for_word_by_word():
    """
    Membaca semua file surah, memecah setiap ayat menjadi kata-kata, dan
    membuat struktur data yang kaya untuk analisis gramatikal mendalam.
    Skrip ini aman untuk dijalankan berulang kali.
    """
    print("Memulai proses penambahan struktur analisis kata mendalam...")
    ArListem = ArabicLightStemmer()
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
            
            made_changes = False

            # Iterasi melalui setiap ayat dalam data surah
            for verse in surah_content.get('data', []):
                # Cek jika ayat sudah memiliki struktur 'analysis' yang baru untuk menghindari duplikasi
                if 'words' in verse and verse['words'] and 'analysis' in verse['words'][0]:
                    continue

                aya_text = verse.get('aya_text', '')
                
                # Memecah teks Arab berdasarkan spasi.
                arabic_words = aya_text.split(' ')
                
                word_list = []
                for index, word in enumerate(arabic_words):
                    if word: # Pastikan kata tidak kosong
                        stripped_word = araby.strip_tashkeel(word)
                        ArListem.light_stem(stripped_word)
                        root_word = ArListem.get_stem()

                        # Struktur data baru yang lebih kaya untuk analisis mendalam
                        word_entry = {
                            "position": index + 1,
                            "arabic": word,
                            "transliteration": "", # Placeholder untuk Anda isi
                            "translation": "",     # Placeholder untuk Anda isi
                            
                            # Bagian Analisis Gramatikal
                            "analysis": {
                                "root": root_word,
                                "lemma": "",       # Placeholder untuk Lemma/Bentuk Dasar
                                "grammar": "",     # Placeholder untuk Detail Grammar (misal: "Noun, Genitive Case")
                                "verb_form": "",   # Placeholder untuk Bentuk Kata Kerja (misal: "Form IV")
                                "occurrences": 0   # Placeholder untuk Jumlah Kemunculan
                            }
                        }
                        word_list.append(word_entry)
                
                # Tambahkan list kata-kata ke objek ayat
                verse['words'] = word_list
                made_changes = True

            # Tulis kembali data HANYA JIKA ada perubahan
            if made_changes:
                with open(file_name, 'w', encoding='utf-8') as f:
                    json.dump(surah_content, f, ensure_ascii=False, indent=4)

        except Exception as e:
            print(f"Gagal memproses {file_name}: {e}")
            
    print("\nProses selesai!")
    print("Semua file surah sekarang memiliki struktur 'analysis' di setiap kata, siap untuk diisi.")

if __name__ == "__main__":
    process_all_surahs_for_word_by_word()

