import 'package:flutter/material.dart';
import '../models/ayah_model.dart';

class GrammarPopup extends StatelessWidget {
  final Grammar grammar;

  const GrammarPopup({
    super.key,
    required this.grammar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          Text(
            grammar.wordAr,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'LPMQ',
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(grammar.grammarFormDesc),
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info(context, 'Arti (Indonesia)', grammar.meaningID),
            _info(context, 'Arti (English)', grammar.meaningEn),
            const Divider(),

            _info(context, 'Akar Kata (Arab)', grammar.rootAr),
            _info(context, 'Akar Kata (English)', grammar.rootEn),
            _info(context, 'Kode Akar', grammar.rootCode),
            const Divider(),

            _info(context, 'Surah', grammar.chapterNo.toString()),
            _info(context, 'Ayat', grammar.verseNo.toString()),
            _info(context, 'Nomor Kata', grammar.wordNo.toString()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _info(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15),
          children: [
            TextSpan(
              text: '$title:\n',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}
