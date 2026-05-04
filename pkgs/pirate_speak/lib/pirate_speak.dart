import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';

const Map<String, String> allLanguages = {
  'en': '🇺🇸 EN',
  'pirate_en': '🏴‍☠️ EN',
  'es': '🇪🇸 ES',
  'pirate_es': '🏴‍☠️ ES',
  'nl': '🇳🇱 NL',
  'pirate_nl': '🏴‍☠️ NL',
  'fr': '🇫🇷 FR',
  'pirate_fr': '🏴‍☠️ FR',
  'pt': '🇵🇹 PT',
  'pirate_pt': '🏴‍☠️ PT',
  'de': '🇩🇪 DE',
  'pirate_de': '🏴‍☠️ DE',
  'zh': '🇨🇳 ZH',
  'pirate_zh': '🏴‍☠️ ZH',
};

String currentLanguage = 'en';
Map<String, String> _translations = {};

Future<void> loadTranslations(String lang) async {
  try {
    final jsonStr = await rootBundle.loadString(
      'packages/pirate_speak/assets/translations/$lang.json',
    );
    _translations = Map<String, String>.from(json.decode(jsonStr));
    currentLanguage = lang;
  } catch (e) {
    // ignore: avoid_print
    print('Failed to load translations for $lang: $e');
  }
}

Future<List<String>> loadAvailableLanguages() async {
  final langs = <String>[];
  for (final lang in allLanguages.keys) {
    try {
      await rootBundle.loadString(
        'packages/pirate_speak/assets/translations/$lang.json',
      );
      langs.add(lang);
    } catch (e) {
      // Ignore failed loads
    }
  }
  if (!langs.contains('en')) langs.add('en');
  return langs;
}

@RecordUse()
String translate(
  @mustBeConst String key,
) {
  return _translations[key] ?? key;
}

@RecordUse()
String translateDynamic(
  String key,

  @mustBeConst String category,
) {
  return _translations[key] ?? key;
}

@visibleForTesting
void setTranslationsForTesting(Map<String, String> translations) {
  _translations = translations;
}
