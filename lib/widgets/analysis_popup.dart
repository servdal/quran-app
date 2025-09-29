// lib/widgets/analysis_popup.dart

import 'package:flutter/material.dart';
import 'package:quran_app/models/ayah_model.dart';

class AnalysisPopup extends StatelessWidget {
  final Word word;
  final AnalysisDetail analysis; // Diubah untuk menerima AnalysisDetail

  const AnalysisPopup({super.key, required this.word, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Analisis Kata", style: TextStyle(fontSize: 16)),
          Text(word.arabic, style: const TextStyle(fontFamily: 'LPMQ', fontSize: 28)),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Ditemukan: ${analysis.occurrences} kali dalam Al-Quran.'),
            const Divider(height: 24),
            ...analysis.parts.map((part) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bagian ${part.partNumber}: ${part.grammar}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("   • Lemma: ${part.lemma}"),
                  if (part.verbForm != 'N/A') Text("   • Bentuk Kata: ${part.verbForm}"),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Tutup'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}