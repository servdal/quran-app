import os
import json

# Konfigurasi
SUMBER_FOLDER = 'surah' 
OUTPUT_FILE = 'root_word_dictionary.json'

def create_root_word_dictionary():
    """
    Membaca semua file surah, mengumpulkan semua root_word unik,
    dan membuat satu file JSON sebagai kamus untuk diisi.
    """
    unique_roots = set()
    print("Memulai pengumpulan kata dasar unik dari semua surah...")

    # Loop dari surah 1 hingga 114
    for surah_id in range(1, 115):
        file_name = os.path.join(SUMBER_FOLDER, f"{surah_id}.json")
        if not os.path.exists(file_name):
            continue

        try:
            with open(file_name, 'r', encoding='utf-8') as f:
                surah_content = json.load(f)

            # Iterasi melalui setiap ayat dan setiap kata
            for verse in surah_content.get('data', []):
                for word in verse.get('words', []):
                    root = word.get('root_word')
                    if root:
                        unique_roots.add(root)
        except Exception as e:
            print(f"Gagal memproses {file_name}: {e}")
            
    print(f"Ditemukan {len(unique_roots)} kata dasar unik.")

    # Ubah set menjadi struktur kamus
    root_word_dict = {
        root: {
            "translation": "",     # Placeholder untuk Anda isi
            "transliteration": ""  # Placeholder untuk Anda isi
        } 
        for root in sorted(list(unique_roots)) # Diurutkan agar mudah dibaca
    }

    # Tulis hasil ke file output
    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(root_word_dict, f, ensure_ascii=False, indent=4)
        print(f"\nBerhasil! File kamus '{OUTPUT_FILE}' telah dibuat.")
        print("Silakan isi terjemahan dan transliterasi di dalam file tersebut.")
    except Exception as e:
        print(f"\nGagal menulis file kamus: {e}")

if __name__ == "__main__":
    create_root_word_dictionary()
