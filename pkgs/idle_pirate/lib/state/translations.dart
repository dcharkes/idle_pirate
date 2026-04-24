import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';
// ignore: unused_import
import 'package:record_use/record_use.dart';

String currentLanguage = 'en';
Map<String, String> _translations = {};

Future<void> loadTranslations(String lang) async {
  try {
    final data = await rootBundle.load('packages/idle_pirate/assets/translations/$lang.json');
    final jsonStr = utf8.decode(data.buffer.asUint8List());
    _translations = Map<String, String>.from(json.decode(jsonStr));
    currentLanguage = lang;
  } catch (e) {
    // ignore: avoid_print
    print('Failed to load translations for $lang: $e');
  }
}

// ignore: experimental_member_use
@RecordUse()
String translate(
  // ignore: experimental_member_use
  @mustBeConst String key,
) {
  return _translations[key] ?? key;
}

// ignore: experimental_member_use
@RecordUse()
String translateDynamic(
  String key,
  // ignore: experimental_member_use
  @mustBeConst String category,
) {
  return _translations[key] ?? key;
}

@visibleForTesting
void setTranslationsForTesting(Map<String, String> translations) {
  _translations = translations;
}
