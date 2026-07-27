import 'package:flutter/material.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/utils/auto_tajweed_parser.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

List<TextSpan> buildArabicSourceSpans({
  required ArabicSource source,
  required String quranCloudText,
  required String quranCloudTajweedText,
  required String kemenagText,
  required TextStyle baseStyle,
  required String lang,
  bool learningMode = false,
  String? activeKey,
  ValueChanged<String>? onTapRule,
  VoidCallback? onClosePopup,
  BuildContext? context,
}) {
  return switch (source) {
    ArabicSource.quranCloudTajweed => TajweedParser.parse(
      quranCloudTajweedText,
      baseStyle,
      lang: lang,
      learningMode: learningMode,
      activeKey: activeKey,
      onTapRule: onTapRule,
      onClosePopup: onClosePopup,
      context: context,
    ),
    ArabicSource.kemenagTajweed => AutoTajweedParser.parse(
      kemenagText,
      baseStyle,
      lang: lang,
      learningMode: learningMode,
      activeKey: activeKey,
      onTapRule: onTapRule,
      onClosePopup: onClosePopup,
      context: context,
    ),
    ArabicSource.quranCloud => [
      TextSpan(text: quranCloudText, style: baseStyle),
    ],
    ArabicSource.kemenag => [TextSpan(text: kemenagText, style: baseStyle)],
  };
}
