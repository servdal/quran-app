// lib/data/aqidah_data.dart

// Model untuk setiap bait nadham
class NadhamItem {
  final int verseNumber;
  final String arabicText;
  final String latinText;
  final String translation;

  NadhamItem({
    required this.verseNumber,
    required this.arabicText,
    required this.latinText,
    required this.translation,
  });
}

// Pengantar singkat tentang kitab
const String aqidahMuqaddimah =
    "Kitab Aqidatul Awam adalah salah satu kitab dasar mengenai ilmu tauhid (aqidah) bagi umat Islam. Kitab ini disusun dalam bentuk syair atau nadham oleh Syeh Ahmad Marzuqi Al-Maliki Al-Hasani. Isinya merangkum sifat-sifat wajib, mustahil, dan jaiz bagi Allah, serta para rasul-Nya.";

// --- Daftar Bait Nadham Aqidatul Awam (Lengkap 57 Bait) ---
final List<NadhamItem> aqidatulAwam = [
  NadhamItem(
    verseNumber: 1,
    arabicText: "أَبْدَأُ بِاسْمِ اللهِ وَالرَّحْمَنِ * وَبِالرَّحِيْمِ دَائِمِ اْلإِحْسَانِ",
    latinText: "Abda-u Bismillahi warrahmaani * Wa birrahiimi daa-imil ihsaani",
    translation: "Aku memulai dengan nama Allah, Dzat yang Maha Pengasih, dan Maha Penyayang yang senantiasa melimpahkan kebaikan.",
  ),
  NadhamItem(
    verseNumber: 2,
    arabicText: "فَالْحَمْدُ ِللهِ الْقَدِيْمِ اْلأَوَّلِ * اْلآخِرِ الْبَاقِيْ بِلاَ تَحَوُّلِ",
    latinText: "Falhamdulillahi-qodiimil awwali * Al aakhiril baaqii bilaa tahawwuli",
    translation: "Maka segala puji bagi Allah yang Maha Dahulu, yang Maha Awal, yang Maha Akhir, yang Maha Kekal tanpa ada perubahan.",
  ),
  NadhamItem(
    verseNumber: 3,
    arabicText: "ثُمَّ الصَّلاَةُ وَالسَّلاَمُ سَرْمَدَا * عَلَى النَّبِيِّ خَيْرِ مَنْ قَدْ وَحَّدَا",
    latinText: "Tsummas sholaatu wassalaamu sarmada * ‘Alan nabiyyi khoiri man qod wahhadaa",
    translation: "Kemudian, semoga shalawat dan salam senantiasa tercurahkan, atas Nabi sebaik-baiknya orang yang mengesakan Allah.",
  ),
  NadhamItem(
    verseNumber: 4,
    arabicText: "وَآلِهِ وَصَحْبِهِ وَمَنْ تَبِعْ * سَبِيْلَ دِيْنِ الْحَقِّ غَيْرَ مُبْتَدِعْ",
    latinText: "Wa aalihii wa shohbihii wa man tabi' * Sabiila diinil haqqi ghoiro mubtadi'",
    translation: "Dan keluarga beliau, sahabatnya, dan orang-orang yang mengikuti jalan agama yang benar bukan orang-orang yang berbuat bid’ah.",
  ),
  NadhamItem(
    verseNumber: 5,
    arabicText: "وَبَعْدُ فَاعْلَمْ بِوُجُوْبِ الْمَعْرِفَةْ * مِنْ وَاجِبٍ ِللهِ عِشْرِيْنَ صِفَةْ",
    latinText: "Wa ba'du fa'lam biwujuubil ma'rifah * Min waajibin lillahi 'isyriina shifah",
    translation: "Dan setelahnya, ketahuilah dengan wajib mengetahui 20 sifat wajib bagi Allah.",
  ),
  // --- Lanjutan Bait Syair ---
  NadhamItem(
    verseNumber: 6,
    arabicText: "فَاللهُ مَوْجُوْدٌ قَدِيْمٌ بَاقِي * مُخَالِفٌ لِلْخَلْقِ بِاْلإِطْلاَقِ",
    latinText: "Fallahu maujudun qodimun baaqi * Mukholifun lilkholqi bil itlaaqi",
    translation: "Allah itu Ada, Terdahulu, Kekal, dan sama sekali berbeda dengan makhluk-Nya.",
  ),
  NadhamItem(
    verseNumber: 7,
    arabicText: "وَقَائِمٌ غَنِيٌّ وَوَاحِدٌ وَحَيّ * قَادِرٌ مُرِيْدٌ عَالِمٌ بِكُلِّ شَيْ",
    latinText: "Wa qooimun ghoniyyun wa wahidun wa hay * Qodirun muridun ‘alimun bikulli syai",
    translation: "Berdiri sendiri, Maha Kaya, Maha Esa, Maha Hidup, Maha Kuasa, Maha Berkehendak, Maha Mengetahui atas segala sesuatu.",
  ),
  NadhamItem(
    verseNumber: 8,
    arabicText: "سَمِيْعٌ اْلبَصِيْرُ وَالْمُتَكَلِّمُ * لَهُ صِفَاتٌ سَبْعَةٌ تَنْتَظِمُ",
    latinText: "Sami’un bashirun wal mutakallimu * Lahu shifatun sab’atun tantadhimu",
    translation: "Maha Mendengar, Maha Melihat, Maha Berfirman. Dia memiliki 7 sifat yang tersusun (Hayat, Ilmu, Qudrat, Iradat, Sama', Bashar, Kalam).",
  ),
  NadhamItem(
    verseNumber: 9,
    arabicText: "فَقُدْرَةٌ إِرَادَةٌ سَمْعٌ بَصَرْ * حَيَاةٌ الْعِلْمُ كَلاَمٌ اسْتَمَرْ",
    latinText: "Faqudrotun irodatun sam’un bashor * Hayatun al’ilmu kalamun istamar",
    translation: "Yaitu Kuasa, Berkehendak, Mendengar, Melihat, Hidup, Memiliki Ilmu, Berfirman secara terus menerus.",
  ),
  NadhamItem(
    verseNumber: 10,
    arabicText: "وَجَائِزٌ بِفَضْلِهِ وَعَدْلِهِ * تَرْكٌ لِكُلِّ مُمْكِنٍ كَفِعْلِهِ",
    latinText: "Wa jaaizun bifadlihi wa ‘adlihi * Tarkun likulli mumkinin kafi’lihi",
    translation: "Dan sifat jaiz-Nya, dengan karunia dan keadilan-Nya, adalah boleh mengerjakan atau meninggalkan segala sesuatu yang mungkin.",
  ),
  NadhamItem(
    verseNumber: 11,
    arabicText: "أَرْسَلَ أَنْبِيَا ذَوِي فَطَانَةْ * بِالصِّدْقِ وَالتَّبْلِيْغِ وَاْلأَمَانَةْ",
    latinText: "Arsala anbiya dawi fatonah * Bissidqi wattablighi wal amanah",
    translation: "Allah mengutus para Nabi yang memiliki kecerdasan, serta sifat benar, menyampaikan (risalah), dan dapat dipercaya.",
  ),
  NadhamItem(
    verseNumber: 12,
    arabicText: "وَجَائِزٌ فِي حَقِّهِمْ مِنْ عَرَضِ * بِغَيْرِ نَقْصٍ كَخَفِيْفِ الْمَرَضِ",
    latinText: "Wa jaaizun fi haqqihim min ‘arodhi * Bighoiri naqshin kakhofiifil marodhi",
    translation: "Dan boleh bagi mereka (para nabi) sifat-sifat manusia biasa yang tidak mengurangi derajatnya, seperti sakit yang ringan.",
  ),
  NadhamItem(
    verseNumber: 13,
    arabicText: "عِصْمَتُهُمْ كَسَائِرِ الْمَلاَئِكَةْ * وَاجِبَةٌ وَفَاضَلُوا الْمَلاَئِكَةْ",
    latinText: "‘Ishmatuhum kasaairil malaaikah * Waajibatun wa fadholul malaaikah",
    translation: "Mereka terjaga (dari dosa) seperti para malaikat. Terjaga adalah wajib, dan mereka lebih utama dari para malaikat.",
  ),
  NadhamItem(
    verseNumber: 14,
    arabicText: "وَالْمُسْتَحِيْلُ ضِدُّ كُلِّ وَاجِبِ * فَاحْفَظْ لِخَمْسِيْنَ بِحُكْمٍ وَاجِبِ",
    latinText: "Wal mustahiilu dhiddu kulli waajibin * Fahfadh likhomsiina bihukmin waajibin",
    translation: "Dan sifat mustahil adalah lawan dari setiap sifat wajib. Maka hafalkanlah 50 sifat itu sebagai hukum yang wajib.",
  ),
  NadhamItem(
    verseNumber: 15,
    arabicText: "تَفْصِيْلُهُمْ خَمْسَةٌ وَعِشْرُوْنَ لَزِمْ * كُلَّ مُكَلَّفٍ فَحَقِّقْ وَاغْتَنِمْ",
    latinText: "Tafshiiluhum khomsatun wa ‘isyruuna lazim * Kulla mukallafin fahaqqiq waghtanim",
    translation: "Adapun rincian (nama rasul) ada 25 yang wajib diketahui setiap mukallaf, maka yakinilah dan ambillah keuntungan.",
  ),
  NadhamItem(
    verseNumber: 16,
    arabicText: "هُمْ آدَمٌ اِدْرِيْسُ نُوْحٌ هُوْدُ مَعْ * صَالِحْ وَإِبْرَاهِيْمُ كُلٌّ مُتَّبَعْ",
    latinText: "Hum Adamun Idriisu Nuuhun Huudu ma' * Sholih wa Ibrohimu kullun muttaba'",
    translation: "Mereka adalah Adam, Idris, Nuh, Hud, serta Shalih dan Ibrahim yang semuanya diikuti.",
  ),
  NadhamItem(
    verseNumber: 17,
    arabicText: "لُوْطٌ وَاِسْمَاعِيْلُ اِسْحَاقُ كَذَا * يَعْقُوْبُ يُوْسُفُ وَأَيُّوْبُ احْتَذَى",
    latinText: "Luuthun wa Isma'ilu Ishaaqu kadza * Ya'qubu Yusufu wa Ayyubuhtadza",
    translation: "Luth, Ismail, Ishaq, demikian pula Ya'qub, Yusuf, dan Ayyub yang meneladani.",
  ),
  NadhamItem(
    verseNumber: 18,
    arabicText: "شُعَيْبُ هَارُوْنُ وَمُوْسَى وَالْيَسَعْ * ذُو الْكِفْلِ دَاوُدُ سُلَيْمَانُ اتَّبَعْ",
    latinText: "Syu'aibu Harunu wa Musa wal Yasa' * Dzul Kifli Dawudu Sulaimanuttaba'",
    translation: "Syu'aib, Harun, Musa dan Alyasa', Dzulkifli, Dawud, Sulaiman yang diikuti.",
  ),
  NadhamItem(
    verseNumber: 19,
    arabicText: "إِلْيَاسُ يُوْنُسُ زَكَرِيَّا يَحْيَى * عِيْسَى وَطَهَ خَاتِمٌ دَعْ غَيَّا",
    latinText: "Ilyasu Yunusu Zakariyya Yahya * ‘Isa wa Thoha khotimun da' ghoyya",
    translation: "Ilyas, Yunus, Zakaria, Yahya, Isa dan Thaha (Muhammad) sang penutup, tinggalkanlah kesesatan.",
  ),
  NadhamItem(
    verseNumber: 20,
    arabicText: "عَلَيْهِمُ الصَّلاَةُ وَالسَّلاَمُ * وَآلِهِمْ مَا دَامَتِ اْلأَيَّامُ",
    latinText: "‘Alaihimus sholatu wassalaamu * Wa aalihim madamatil ayyamu",
    translation: "Semoga shalawat dan salam tercurah atas mereka dan keluarga mereka sepanjang masa.",
  ),
  NadhamItem(
    verseNumber: 21,
    arabicText: "وَالْمَلَكُ الَّذِيْ بِلاَ أَبٍ وَأُمْ * لاَ أَكْلَ لاَ شُرْبَ وَلاَ نَوْمَ لَهُمْ",
    latinText: "Wal malakul ladzi bilaa abin wa um * Laa akla laa syurba wa laa nauma lahum",
    translation: "Dan Malaikat adalah yang tanpa ayah dan ibu, tidak makan, tidak minum, dan tidak tidur.",
  ),
  NadhamItem(
    verseNumber: 22,
    arabicText: "تَفْصِيْلُهُمْ عَشْرٌ مِنْهُمْ جِبْرِيْلُ * مِيْكَالُ اِسْرَافِيْلُ عِزْرَائِيْلُ",
    latinText: "Tafshiiluhum ‘asyrun minhum Jibrilu * Mikalu Isrofilu ‘Izrooilu",
    translation: "Rinciannya ada sepuluh, di antaranya Jibril, Mikail, Israfil, Izrail.",
  ),
  NadhamItem(
    verseNumber: 23,
    arabicText: "مُنْكَرْ نَكِيْرٌ وَرَقِيْبٌ وَكَذَا * عَتِيْدٌ مَالِكٌ وَرِضْوَانُ احْتَذَى",
    latinText: "Munkar Nakirun wa Roqibun wa kadza * ‘Atidun Maliki wa Ridwanuhtadza",
    translation: "Munkar, Nakir, dan Raqib, demikian pula 'Atid, Malik, dan Ridwan yang mengikuti.",
  ),
  NadhamItem(
    verseNumber: 24,
    arabicText: "أَرْبَعَةٌ مِنْ كُتُبٍ تَفْصِيْلُهَا * تَوْرَاةُ مُوْسَى بِالْهُدَى تَنْزِيْلُهَا",
    latinText: "Arba'atun min kutubin tafshiiluha * Tauratu Musa bil huda tanziiluha",
    translation: "Empat dari kitab-kitab suci rinciannya adalah Taurat bagi Musa diturunkan dengan petunjuk.",
  ),
  NadhamItem(
    verseNumber: 25,
    arabicText: "زَبُوْرُ دَاوُدَ وَاِنْجِيْلُ عَلَى * عِيْسَى وَفُرْقَانُ عَلَى خَيْرِ الْمَلاَ",
    latinText: "Zaburu Dawuda wa Injilu ‘ala * ‘Isa wa Furqonu ‘ala khoiril mala",
    translation: "Zabur bagi Dawud dan Injil bagi Isa, dan Al-Furqan (Al-Quran) bagi sebaik-baiknya manusia (Muhammad).",
  ),
  NadhamItem(
    verseNumber: 26,
    arabicText: "وَصُحُفُ الْخَلِيْلِ وَالْكَلِيْمِ * فِيْهَا كَلاَمُ الْحَكَمِ الْعَلِيْمِ",
    latinText: "Wa shuhuful kholili wal kalimi * Fiiha kalamul hakamul ‘alimi",
    translation: "Dan lembaran-lembaran (Shuhuf) bagi Al-Khalil (Ibrahim) dan Al-Kalim (Musa), di dalamnya terdapat firman dari Dzat yang Maha Bijaksana lagi Maha Mengetahui.",
  ),
  NadhamItem(
    verseNumber: 27,
    arabicText: "وَكُلُّ مَا أَتَى بِهِ الرَّسُوْلُ * فَحَقُّهُ التَّسْلِيْمُ وَالْقَبُوْلُ",
    latinText: "Wa kullu maa ata bihir Rasulu * Fahaqqohut tasliimu wal qobulu",
    translation: "Dan segala apa yang datang dari Rasul, maka kewajiban kita adalah pasrah dan menerima.",
  ),
  NadhamItem(
    verseNumber: 28,
    arabicText: "إِيْمَانُنَا بِيَوْمِ آخِرٍ وَجَبْ * وَكُلِّ مَا كَانَ بِهِ مِنَ الْعَجَبْ",
    latinText: "Imanuna biyaumi aakhirin wajab * Wa kulli ma kana bihi minal ‘ajab",
    translation: "Keimanan kita kepada hari akhir adalah wajib, dan segala perkara menakjubkan yang ada di dalamnya.",
  ),
  NadhamItem(
    verseNumber: 29,
    arabicText: "خَاتِمَةٌ فِيْ ذِكْرِ بَاقِي الْوَاجِبِ * مِمَّا عَلَى مُكَلَّفٍ مِنْ وَاجِبِ",
    latinText: "Khotimatun fi dzikri baqil waajibi * Mimma ‘ala mukallafin min waajibi",
    translation: "Sebagai penutup, dalam menyebutkan sisa kewajiban, dari apa yang wajib bagi setiap mukallaf.",
  ),
  NadhamItem(
    verseNumber: 30,
    arabicText: "نَبِيُّنَا مُحَمَّدٌ قَدْ أُرْسِلاَ * لِلْعَالَمِيْنَ رَحْمَةً وَفُضِّلاَ",
    latinText: "Nabiyyuna Muhammadun qod ursila * Lil ‘alamina rohmatan wa fudhila",
    translation: "Nabi kita Muhammad telah diutus, untuk seluruh alam sebagai rahmat dan beliau diutamakan.",
  ),
  NadhamItem(
    verseNumber: 31,
    arabicText: "أَبُوْهُ عَبْدُ اللهِ عَبْدُ الْمُطَّلِبْ * وَهَاشِمٌ عَبْدُ مَنَافٍ يَنْتَسِبْ",
    latinText: "Abuhu ‘Abdullahi ‘Abdul Mutholib * Wa Hasyimun ‘Abdu Manafin yantasib",
    translation: "Ayahnya adalah Abdullah bin Abdul Muthalib, dan nasabnya bersambung pada Hasyim bin Abdu Manaf.",
  ),
  NadhamItem(
    verseNumber: 32,
    arabicText: "وَأُمُّهُ آمِنَةُ الزُّهْرِيَّةْ * أَرْضَعَتْهُ حَلِيْمَةُ السَّعْدِيَّةْ",
    latinText: "Wa ummuhu Aminatus Zuhriyyah * Ardho’athu Halimatus Sa'diyyah",
    translation: "Dan ibunya adalah Aminah Az-Zuhriyyah, yang menyusuinya adalah Halimah As-Sa'diyyah.",
  ),
  NadhamItem(
    verseNumber: 33,
    arabicText: "مَوْلِدُهُ بِمَكَّةَ اْلأَمِيْنَةْ * وَفَاتُهُ بِطَيْبَةَ الْمَدِيْنَةْ",
    latinText: "Mauliduhu bimakkatil aminah * Wafatuhu bithoibatil madinah",
    translation: "Kelahirannya di Makkah yang aman, dan wafatnya di Thaibah (Madinah).",
  ),
  NadhamItem(
    verseNumber: 34,
    arabicText: "أَتَمَّ قَبْلَ الْوَحْيِ أَرْبَعِيْنَا * وَعُمْرُهُ قَدْ جَاوَزَ السِّتِّيْنَا",
    latinText: "Atamma qoblal wahyi arba’ina * Wa ‘umruhu qod jawazas sittina",
    translation: "Beliau genap berusia 40 tahun sebelum menerima wahyu, dan usianya melebihi 60 tahun (tepatnya 63).",
  ),
  NadhamItem(
    verseNumber: 35,
    arabicText: "وَسَبْعَةٌ أَوْلاَدُهُ فَمِنْهُمُ * ثَلاَثَةٌ مِنَ الذُّكُوْرِ تُفْهَمُ",
    latinText: "Wa sab’atun awladuhu faminhumu * Tsalatsatun minadz dzukuri tufhamu",
    translation: "Dan tujuh adalah jumlah anaknya, di antara mereka tiga orang laki-laki, maka pahamilah.",
  ),
  NadhamItem(
    verseNumber: 36,
    arabicText: "قَاسِمْ وَعَبْدُ اللهِ وَهْوَ الطَّيِّبُ * وَطَاهِرٌ بِذَيْنِ ذَا يُلَقَّبُ",
    latinText: "Qosim wa ‘Abdullahi wahwath Thoyyibu * Wa Thohirun bidzaini dza yulaqqobu",
    translation: "Qasim dan Abdullah yang bergelar Ath-Thayyib dan Ath-Thahir, dengan dua sebutan inilah ia dipanggil.",
  ),
  NadhamItem(
    verseNumber: 37,
    arabicText: "أَتَاهُ إِبْرَاهِيْمُ مِنْ سُرِّيَّةْ * فَأُمُّهُ مَارِيَةُ الْقِبْطِيَّةْ",
    latinText: "Atahu Ibrohimu min surriyyah * Fa ummuhu Mariyatul Qibtiyyah",
    translation: "Anaknya Ibrahim dari seorang budak wanita, ibunya adalah Mariyah Al-Qibtiyyah.",
  ),
  NadhamItem(
    verseNumber: 38,
    arabicText: "وَغَيْرُ إِبْرَاهِيْمَ مِنْ خَدِيْجَةْ * هُمْ سِتَّةٌ فَخُذْ بِهِمْ وَلِيْجَةْ",
    latinText: "Wa ghoiru Ibrohima min Khodijah * Hum sittatun fakhud bihim walijah",
    translation: "Dan selain Ibrahim adalah dari Khadijah, mereka berjumlah enam orang, maka kenalilah mereka dengan penuh cinta.",
  ),
  NadhamItem(
    verseNumber: 39,
    arabicText: "وَأَرْبَعٌ مِنَ اْلإِنَاثِ تُذْكَرُ * رِضْوَانُ رَبِّيْ لِلْجَمِيْعِ يُذْكَرُ",
    latinText: "Wa arba’un minal inatsi tudzkaru * Ridhwanu robbi lil jami’i yudzkaru",
    translation: "Dan empat orang dari anak perempuan yang disebutkan, semoga keridhaan Tuhanku bagi mereka semua disebutkan.",
  ),
  NadhamItem(
    verseNumber: 40,
    arabicText: "فَاطِمَةُ الزَّهْرَاءُ بَعْلُهَا عَلِيْ * وَابْنَاهُمَا السِّبْطَانِ فَضْلُهُمْ جَلِيْ",
    latinText: "Fathimatuz Zahro-u ba'luha ‘Ali * Wabnahumas sibthoni fadluhum jali",
    translation: "Fatimah Az-Zahra yang suaminya adalah Ali, dan kedua putranya (Hasan & Husein) adalah dua cucu (Nabi) yang keutamaannya sangat jelas.",
  ),
  NadhamItem(
    verseNumber: 41,
    arabicText: "فَزَيْنَبٌ وَبَعْدَهَا رُقَيَّةْ * وَأُمُّ كُلْثُوْمٍ زَكَتْ رَضِيَّةْ",
    latinText: "Fazaenabun wa ba'daha Ruqoyyah * Wa Ummu Kultsumin zakat rodhiyyah",
    translation: "Maka (setelah Fatimah adalah) Zainab, dan setelahnya Ruqayyah, dan Ummu Kultsum yang suci lagi diridhai.",
  ),
  NadhamItem(
    verseNumber: 42,
    arabicText: "عَنْ تِسْعِ نِسْوَةٍ وَفَاةُ الْمُصْطَفَى * خُيِّرْنَ فَاخْتَرْنَ النَّبِيَّ الْمُقْتَفَى",
    latinText: "‘An tis'i niswatin wafatul Mushthofa * Khuyyirna fakhtarnan nabiyyal muqtafa",
    translation: "Saat wafatnya Al-Mushthafa (Nabi terpilih), beliau meninggalkan sembilan orang istri. Mereka telah diberi pilihan (antara dunia & akhirat), lalu mereka memilih Nabi yang patut diikuti.",
  ),
  NadhamItem(
    verseNumber: 43,
    arabicText: "عَائِشَةٌ وَحَفْصَةٌ وَسَوْدَةْ * صَفِيَّةٌ مَيْمُوْنَةٌ وَرَمْلَةْ",
    latinText: "‘Aisyatun wa Hafshotun wa Saudah * Shofiyyatun Maimunatun wa Romlah",
    translation: "Aisyah, Hafshah, dan Saudah. Shafiyyah, Maimunah, dan Ramlah (Ummu Habibah).",
  ),
  NadhamItem(
    verseNumber: 44,
    arabicText: "هِنْدٌ وَزَيْنَبٌ كَذَا جُوَيْرِيَةْ * لِلْمُؤْمِنِيْنَ أُمَّهَاتٌ مَرْضِيَّةْ",
    latinText: "Hindun wa Zainabun kadza Juwairiyah * Lil mu'minina ummahatun mardhiyyah",
    translation: "Hindun, dan Zainab, begitu pula Juwairiyah. Bagi kaum mukminin, mereka adalah para ibu yang diridhai.",
  ),
  NadhamItem(
    verseNumber: 45,
    arabicText: "حَمْزَةُ عَمُّهُ وَعَبَّاسٌ كَذَا * عَمَّتُهُ صَفِيَّةٌ ذَاتُ احْتِذَا",
    latinText: "Hamzatu ‘ammuhu wa ‘Abbasun kadza * ‘Ammatuhu Shofiyyatun dzatuh tidza",
    translation: "Hamzah adalah paman beliau, dan Abbas juga. Bibi beliau adalah Shafiyyah yang patut diteladani.",
  ),
  NadhamItem(
    verseNumber: 46,
    arabicText: "وَقَبْلَ هِجْرَةِ النَّبِيِّ اْلإِسْرَا * مِنْ مَكَّةَ لَيْلاً لِقُدْسٍ يُدْرَى",
    latinText: "Wa qobla hijrotin nabiyyil isro * Min makkatin lailan liqudsin yudro",
    translation: "Dan sebelum hijrahnya Nabi, terjadi peristiwa Isra', dari Makkah pada malam hari menuju Quds (Baitul Maqdis) yang diketahui.",
  ),
  NadhamItem(
    verseNumber: 47,
    arabicText: "وَبَعْدَ إِسْرَاءٍ عُرُوْجٌ لِلسَّمَا * حَتَّى رَأَى النَّبِيُّ رَبًّا كَلَّمَا",
    latinText: "Wa ba'da isro-in ‘urujun lissama * Hatta ro-an nabiyyu robban kallama",
    translation: "Dan setelah Isra', terjadi Mi'raj (naik) ke langit, hingga Nabi melihat Tuhan yang berfirman.",
  ),
  NadhamItem(
    verseNumber: 48,
    arabicText: "مِنْ غَيْرِ كَيْفٍ وَانْحِصَارٍ وَافْتَرَضْ * عَلَيْهِ خَمْسًا بَعْدَ خَمْسِيْنَ فَرَضْ",
    latinText: "Min ghoiri kaifin wanhishorin waftarod * ‘Alaihi khomsan ba'da khomsiina farod",
    translation: "Tanpa bentuk dan batasan, dan diwajibkan atasnya shalat lima waktu setelah (sebelumnya) lima puluh.",
  ),
  NadhamItem(
    verseNumber: 49,
    arabicText: "وَبَلَّغَ اْلأُمَّةَ بِاْلإِسْرَاءِ * وَفَرْضِ خَمْسَةٍ بِلاَ امْتِرَاءِ",
    latinText: "Wa ballaghol ummata bil isro-i * Wa fardhi khomsatin bilamtiro-i",
    translation: "Dan beliau telah menyampaikan kepada umat tentang peristiwa Isra', dan kewajiban shalat lima waktu tanpa keraguan.",
  ),
  NadhamItem(
    verseNumber: 50,
    arabicText: "قَدْ فَازَ صِدِّيْقٌ بِتَصْدِيْقٍ لَهُ * وَبِالْعُرُوْجِ الصِّدْقُ وَافَى أَهْلَهُ",
    latinText: "Qod faza shiddiqun bitashdiqin lahu * Wa bil ‘uruji shidqu wafaa ahlahu",
    translation: "Sungguh beruntung Ash-Shiddiq (Abu Bakar) dengan membenarkannya, dan dengan peristiwa Mi'raj, kebenaran itu sesuai bagi ahlinya.",
  ),
  NadhamItem(
    verseNumber: 51,
    arabicText: "وَهَذِهِ عَقِيْدَةٌ مُخْتَصَرَةْ * وَلِلْعَوَامِ سَهْلَةٌ مُيَسَّرَةْ",
    latinText: "Wa hadzihi ‘aqidatun mukhtashoroh * Wa lil’awami sahlatun muyassaroh",
    translation: "Dan ini adalah aqidah yang ringkas, dan bagi orang awam mudah lagi dimudahkan.",
  ),
  NadhamItem(
    verseNumber: 52,
    arabicText: "نَاظِمُ تِلْكَ أَحْمَدُ الْمَرْزُوْقِيْ * مَنْ يَنْتَمِيْ لِلصَّادِقِ الْمَصْدُوْقِ",
    latinText: "Nadhimu tilka Ahmadul Marzuqi * Man yantami lishodiqil mashduqi",
    translation: "Penyusun nadham ini adalah Ahmad Al-Marzuqi, yang bernasab kepada Ash-Shadiq Al-Mashduq (Nabi Muhammad).",
  ),
  NadhamItem(
    verseNumber: 53,
    arabicText: "وَالْحَمْدُ ِللهِ وَصَلَّى سَلَّمَا * عَلَى النَّبِيِّ خَيْرِ مَنْ قَدْ عَلَّمَا",
    latinText: "Wal hamdu lillahi wa sholla sallama * ‘Alan nabiyyi khoiri man qod ‘allama",
    translation: "Dan segala puji bagi Allah, serta shalawat dan salam semoga tercurah atas Nabi sebaik-baik orang yang telah mengajar.",
  ),
  NadhamItem(
    verseNumber: 54,
    arabicText: "وَاْلآلِ وَالصَّحْبِ وَكُلِّ مُرْشِدِ * وَكُلِّ مَنْ بِخَيْرِ هَدْيٍ يَقْتَدِيْ",
    latinText: "Wal aali was shohbi wa kulli mursyidi * Wa kulli man bikhoiri hadyin yaqtadi",
    translation: "Dan juga keluarga, sahabat, dan setiap pemberi petunjuk, serta setiap orang yang mengikuti petunjuk terbaik.",
  ),
  NadhamItem(
    verseNumber: 55,
    arabicText: "وَأَسْأَلُ الْكَرِيْمَ إِخْلاَصَ الْعَمَلْ * وَنَفْعَ كُلِّ مَنْ بِهَا قَدِ اشْتَغَلْ",
    latinText: "Wa as-alul karima ikhlashol ‘amal * Wa naf’a kulli man biha qodisytaghol",
    translation: "Dan aku memohon kepada Dzat yang Maha Mulia keikhlasan dalam beramal, dan manfaat bagi setiap orang yang menyibukkan diri dengannya.",
  ),
  NadhamItem(
    verseNumber: 56,
    arabicText: "أَبْيَاتُهَا (مَيْزٌ) بِعَدِّ الْجُمَّلِ * تَارِيْخُهَا (لِيْ حَيُّ غُرٍّ) جُمَّلِ",
    latinText: "Abyatuha (maizun) bi'addil jumali * Tarikhuha (li hayyu ghurrin) jumali",
    translation: "Bait-baitnya berjumlah 'Maizun' (57) dengan hitungan abjad, tahun penulisannya adalah 'Li Hayyu Ghurrin' (1258 H).",
  ),
  NadhamItem(
    verseNumber: 57,
    arabicText: "سَمَّيْتُهَا عَقِيْدَةَ الْعَوَامِ * مِنْ وَاجِبٍ فِي الدِّيْنِ بِالتَّمَامِ",
    latinText: "Sammaituha ‘aqidatal ‘awami * Min wajibin fiddini bittamaami",
    translation: "Aku menamainya 'Aqidatul Awam', yang berisi kewajiban dalam agama secara sempurna.",
  ),
];