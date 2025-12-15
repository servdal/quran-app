// lib/widgets/grammar_popup.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/grammar_model.dart';
import '../providers/settings_provider.dart';

class GrammarPopup extends ConsumerWidget {
  final Grammar grammar;

  const GrammarPopup({
    super.key,
    required this.grammar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isId = settings.language == 'id';

    final meaning = isId ? grammar.meaningId : grammar.meaningEn;
    final grammarDesc =
        isId ? grammar.grammarDescId : grammar.grammarDescEn;

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
            label: Text(grammarDesc.isEmpty ? '-' : grammarDesc),
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info(
              context,
              isId ? 'Arti' : 'Meaning',
              meaning,
            ),
            const Divider(),

            _info(
              context,
              isId ? 'Akar Kata (Arab)' : 'Root (Arabic)',
              grammar.rootAr,
            ),
            _info(
              context,
              isId ? 'Akar Kata (English)' : 'Root (English)',
              grammar.rootEn,
            ),
            _info(
              context,
              isId ? 'Kode Akar' : 'Root Code',
              grammar.rootCode,
            ),
            const Divider(),

            _info(
              context,
              isId ? 'Surah' : 'Chapter',
              grammar.surahId.toString(),
            ),
            _info(
              context,
              isId ? 'Ayat' : 'Verse',
              grammar.ayahNumber.toString(),
            ),
            _info(
              context,
              isId ? 'Nomor Kata' : 'Word No',
              grammar.wordNumber.toString(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isId ? 'Tutup' : 'Close'),
        ),
      ],
    );
  }

  Widget _info(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context)
              .style
              .copyWith(fontSize: 15),
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
