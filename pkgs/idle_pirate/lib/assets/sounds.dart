import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';

// ignore: experimental_member_use
@RecordUse()
final class Sound {
  final String id;
  // ignore: experimental_member_use
  const Sound(@mustBeConst this.id);

  Future<ByteData> load() {
    return rootBundle.load('assets/sounds/$id.mp3');
  }
}
