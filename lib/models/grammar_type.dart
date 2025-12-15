enum GrammarType { fiil, isim, harf, other }

GrammarType detectGrammarType(String desc) {
  final d = desc.toLowerCase();
  if (d.contains('verb')) return GrammarType.fiil;
  if (d.contains('noun')) return GrammarType.isim;
  if (d.contains('particle')) return GrammarType.harf;
  return GrammarType.other;
}
