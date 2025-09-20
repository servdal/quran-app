// lib/screens/aqidah_screen.dart

import 'package:flutter/material.dart';
import 'package:quran_app/data/aqidah_data.dart';

class AqidahScreen extends StatelessWidget {
  const AqidahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nadham Aqidatul Awam'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        // Jumlah item adalah jumlah bait + 1 untuk mukadimah
        itemCount: aqidatulAwam.length + 1,
        itemBuilder: (context, index) {
          // Item pertama adalah mukadimah
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
                      "Tentang Kitab",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 16),
                    Text(
                      aqidahMuqaddimah,
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Item selanjutnya adalah bait-bait nadham
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
                  CircleAvatar(
                    child: Text(nadham.verseNumber.toString()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nadham.arabicText,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'LPMQ', fontSize: 22, height: 2.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nadham.latinText,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const Divider(height: 24),
                  Text(
                    nadham.translation,
                    textAlign: TextAlign.justify,
                    style: Theme.of(context).textTheme.bodyMedium,
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