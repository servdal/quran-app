import os
import json

# Konfigurasi
SUMBER_FOLDER = 'surah'
DICTIONARY_FILE = 'root_word_dictionary.json'

def apply_dictionary_to_surahs():
    """
    Membaca kamus yang sudah diisi dan menerapkan terjemahan/transliterasi
    ke semua kata yang cocok di setiap file surah.
    """
    # 1. Muat kamus
    if not os.path.exists(DICTIONARY_FILE):
        print(f"Error: File kamus '{DICTIONARY_FILE}' tidak ditemukan.")
        return
        
    with open(DICTIONARY_FILE, 'r', encoding='utf-8') as f:
        dictionary = json.load(f)
    
    print("Kamus berhasil dimuat. Memulai penerapan ke file surah...")

    # 2. Loop melalui semua file surah
    for surah_id in range(1, 115):
        file_name = os.path.join(SUMBER_FOLDER, f"{surah_id}.json")
        if not os.path.exists(file_name):
            continue

        try:
            with open(file_name, 'r', encoding='utf-8') as f:
                surah_content = json.load(f)

            made_changes = False
            # 3. Iterasi melalui setiap ayat dan kata
            for verse in surah_content.get('data', []):
                for word in verse.get('words', []):
                    root = word.get('root_word')
                    
                    # 4. Cari kata dasar di kamus
                    if root and root in dictionary:
                        dict_entry = dictionary[root]
                        
                        # 5. Perbarui jika terjemahan/transliterasi masih kosong
                        if not word.get('translation') and dict_entry.get('translation'):
                            word['translation'] = dict_entry['translation']
                            made_changes = True
                        if not word.get('transliteration') and dict_entry.get('transliteration'):
                            word['transliteration'] = dict_entry['transliteration']
                            made_changes = True

            # 6. Simpan file HANYA jika ada perubahan
            if made_changes:
                with open(file_name, 'w', encoding='utf-8') as f:
                    json.dump(surah_content, f, ensure_ascii=False, indent=4)
                print(f"Perubahan diterapkan pada {file_name}")

        except Exception as e:
            print(f"Gagal memproses {file_name}: {e}")
            
    print("\nProses selesai!")
    print("Semua file surah telah diperbarui berdasarkan kamus Anda.")

if __name__ == "__main__":
    apply_dictionary_to_surahs()
