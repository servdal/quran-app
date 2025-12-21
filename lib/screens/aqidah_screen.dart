// lib/screens/aqidah_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Tambahkan Riverpod
import 'package:quran_app/data/aqidah_data.dart';
import 'package:quran_app/providers/settings_provider.dart'; // Sesuaikan path provider Anda

// Ubah menjadi ConsumerWidget agar bisa mengakses 'ref'
class AqidahScreen extends ConsumerWidget {
  const AqidahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(settingsProvider).language;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'id' ? 'Nadham Aqidatul Awam' : 'Aqidatul Awam Poem'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: aqidatulAwam.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aqidahMuqaddimah[lang] ?? aqidahMuqaddimah['id']!,
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final nadham = aqidatulAwam[index - 1];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nomor Bait
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        nadham.verseNumber.toString(),
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Teks Arab
                  Text(
                    nadham.arabicText,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'LPMQ', // Pastikan font terdaftar di pubspec
                      fontSize: 24, 
                      height: 2.0
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Latin
                  Text(
                    nadham.latinText,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600]
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    nadham.getTranslation(lang),
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}