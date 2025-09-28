import os
import json
from collections import defaultdict

# Konfigurasi
SUMBER_FOLDER = 'surah' 
OUTPUT_FILE = 'root_word_dictionary.json'

def create_root_word_dictionary():
    """
    Membaca semua file surah, mengumpulkan semua root_word,
    dan membuat kamus root lengkap dengan lokasi kemunculan dan jumlahnya.
    """
    root_word_dict = defaultdict(lambda: {
        "translation": "",
        "transliteration": "",
        "lemma": "",
        "grammar": "",
        "verb_form": "",
        "occurrences": 0,
        "occurrence_locations": []
    })

    print("Memulai pengumpulan kata dasar dari semua surah...")

    # Loop dari surah 1 hingga 114
    for surah_id in range(1, 115):
        file_name = os.path.join(SUMBER_FOLDER, f"{surah_id}.json")
        if not os.path.exists(file_name):
            print(f"File tidak ditemukan: {file_name}")
            continue

        try:
            with open(file_name, 'r', encoding='utf-8') as f:
                surah_content = json.load(f)

            for verse in surah_content.get('data', []):
                ayah_number = verse.get('aya_number', None)
                if not ayah_number:
                    continue

                for word in verse.get('words', []):
                    root = word.get('analysis', {}).get('root')
                    if root:
                        # Bersihkan root dari karakter spesial yang tidak diperlukan
                        root = root.strip("ۙۖۚۛۗۜۘۙۖۚۛۗۜۘ")

                        # Tambahkan jumlah kemunculan
                        root_word_dict[root]["occurrences"] += 1

                        # Tambahkan lokasi kemunculan jika belum tercatat
                        root_word_dict[root]["occurrence_locations"].append({
                            "surah_id": surah_id,
                            "ayah_number": ayah_number
                        })

        except Exception as e:
            print(f"Gagal memproses {file_name}: {e}")
            
    print(f"Ditemukan {len(root_word_dict)} kata dasar unik.")

    # Ubah ke dictionary biasa untuk disimpan ke JSON
    root_word_dict = dict(root_word_dict)

    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(root_word_dict, f, ensure_ascii=False, indent=4)
        print(f"\nBerhasil! File kamus '{OUTPUT_FILE}' telah dibuat.")
    except Exception as e:
        print(f"\nGagal menulis file kamus: {e}")

if __name__ == "__main__":
    create_root_word_dictionary()
