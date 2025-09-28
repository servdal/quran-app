import os
import json
from collections import defaultdict

# Folder input dan output
FOLDER_SURAHS = "surah"
FOLDER_PAGES = "pages"

# Buat folder output jika belum ada
os.makedirs(FOLDER_PAGES, exist_ok=True)

def split_surah_by_page():
    print("📖 Memulai proses pemisahan per halaman...")
    
    # Semua file surah dalam folder
    for filename in os.listdir(FOLDER_SURAHS):
        if not filename.endswith(".json"):
            continue

        surah_path = os.path.join(FOLDER_SURAHS, filename)

        with open(surah_path, 'r', encoding='utf-8') as f:
            surah_data = json.load(f)

        surah_id = surah_data.get("sura_id")
        surah_name = surah_data.get("name")
        ayat = surah_data.get("data", [])

        print(f"📂 Memproses Surah {surah_id} - {surah_name} ({len(ayat)} ayat)")

        # Kumpulkan ayat-ayat berdasarkan page_number
        pages_dict = defaultdict(list)

        for verse in ayat:
            page = verse.get("page_number")
            if page is not None:
                pages_dict[page].append(verse)

        # Tulis file per halaman
        for page_number, verses in pages_dict.items():
            page_file_path = os.path.join(FOLDER_PAGES, f"{page_number}.json")

            # Jika file sudah ada, baca dan gabungkan
            if os.path.exists(page_file_path):
                with open(page_file_path, 'r', encoding='utf-8') as pf:
                    existing_data = json.load(pf)
                existing_data['data'].extend(verses)
            else:
                existing_data = {
                    "page_number": page_number,
                    "data": verses
                }

            # Simpan file halaman
            with open(page_file_path, 'w', encoding='utf-8') as pf:
                json.dump(existing_data, pf, ensure_ascii=False, indent=4)

            print(f"  ✅ Halaman {page_number} → {len(verses)} ayat ditulis ke pages/{page_number}.json")

    print("✅ Selesai memisahkan seluruh surah ke dalam file per halaman.")

if __name__ == "__main__":
    split_surah_by_page()
