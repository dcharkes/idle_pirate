import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

final class Sound {
  final String id;
  const Sound(this.id);

  Future<ByteData> load() {
    return rootBundle.load('assets/sounds/$id.mp3');
  }
}
