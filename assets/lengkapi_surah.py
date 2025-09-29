import json
import os
import re
from tqdm import tqdm

# --- Konfigurasi Nama File ---
MORPHOLOGY_FILE = 'quranic-corpus-morphology-0.4.txt'
ROOT_DICT_FILE = 'root_word_dictionary.json'
SURAH_FOLDER = 'surah'

def parse_features(feature_str):
    """
    Fungsi untuk mem-parsing kolom FEATURES dari file morfologi.
    Contoh: STEM|POS:N|LEM:{som|ROOT:smw|M|GEN
    """
    features = {}
    parts = feature_str.split('|')
    for part in parts:
        if ':' in part:
            key, value = part.split(':', 1)
            # Membersihkan nilai LEM dan ROOT
            if key == 'LEM':
                features['lemma'] = value.split('{')[1] if '{' in value else value
            elif key == 'ROOT':
                features['root'] = value
            else:
                features[key.lower()] = value
    
    # Menambahkan TAG utama (misal: N, P, V) ke dalam grammar
    tag = parts[0] if parts else ''
    if 'pos' in features:
        features['grammar'] = f"{tag} ({features['pos']})"
    else:
        features['grammar'] = tag

    return features

def load_morphology_data():
    """
    Memuat dan mem-parsing seluruh file morfologi ke dalam sebuah dictionary.
    """
    print(f"Membaca dan memproses {MORPHOLOGY_FILE}...")
    morphology_data = {}
    with open(MORPHOLOGY_FILE, 'r', encoding='utf-8') as f:
        # Melewati header
        next(f) 
        for line in tqdm(f, desc="Memproses Morfologi"):
            if line.strip():
                try:
                    location, form, tag, features_str = line.strip().split('\t')
                    loc_parts = location.strip('()').split(':')
                    
                    # --- PERBAIKAN DI SINI ---
                    # Pastikan lokasi memiliki setidaknya 3 bagian (surah:ayat:kata)
                    if len(loc_parts) >= 3:
                        main_location_key = f"{loc_parts[0]}:{loc_parts[1]}:{loc_parts[2]}"

                        # Hanya proses STEM (kata inti), bukan prefix atau suffix
                        if 'STEM' in features_str:
                            parsed = parse_features(features_str)
                            morphology_data[main_location_key] = {
                                "root": parsed.get("root", ""),
                                "lemma": parsed.get("lemma", ""),
                                "grammar": parsed.get("grammar", ""),
                                "verb_form": "", # Verb form tidak tersedia secara langsung
                            }
                except ValueError:
                    # Melewati baris yang mungkin tidak memiliki 4 kolom
                    pass
    return morphology_data

def main():
    """
    Fungsi utama untuk menjalankan proses pembaruan data.
    """
    # 1. Periksa ketersediaan file
    if not all(os.path.exists(f) for f in [MORPHOLOGY_FILE, ROOT_DICT_FILE, SURAH_FOLDER]):
        print("Error: Pastikan file 'quranic-corpus-morphology-0.4.txt', 'root_word_dictionary.json', dan folder 'surah/' ada di direktori yang sama.")
        return

    # 2. Muat semua data yang diperlukan
    morphology_data = load_morphology_data()
    
    print(f"Memuat {ROOT_DICT_FILE}...")
    with open(ROOT_DICT_FILE, 'r', encoding='utf-8') as f:
        root_dictionary = json.load(f)

    # 3. Dapatkan daftar file surah
    try:
        surah_files = [f for f in os.listdir(SURAH_FOLDER) if f.endswith('.json')]
        surah_files.sort(key=lambda x: int(os.path.splitext(x)[0]))
    except FileNotFoundError:
        print(f"Error: Folder '{SURAH_FOLDER}' tidak ditemukan.")
        return

    print(f"\nMenemukan {len(surah_files)} file surah untuk diperbarui.")

    # 4. Iterasi dan perbarui setiap file surah
    for filename in tqdm(surah_files, desc="Memperbarui Surah"):
        filepath = os.path.join(SURAH_FOLDER, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            surah_data = json.load(f)

        is_updated = False
        for ayah in surah_data.get('data', []):
            for word in ayah.get('words', []):
                location_key = f"{surah_data['sura_id']}:{ayah['aya_number']}:{word['position']}"

                if location_key in morphology_data:
                    word_morph_data = morphology_data[location_key]
                    root_key = word_morph_data.get('root', '')
                    root_info = root_dictionary.get(root_key, {})

                    word['analysis'] = {
                        "root": root_key,
                        "lemma": word_morph_data.get('lemma', ''),
                        "grammar": word_morph_data.get('grammar', ''),
                        "verb_form": word_morph_data.get('verb_form', ''),
                        "occurrences": root_info.get('occurrences', 0),
                        "occurrence_locations": root_info.get('occurrence_locations', [])
                    }
                    is_updated = True

        # 5. Simpan file jika ada perubahan
        if is_updated:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(surah_data, f, ensure_ascii=False, indent=4)

    print("\n✅ Proses selesai! Semua file surah telah berhasil diperbarui.")

if __name__ == "__main__":
    main()