// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// The C build specification for the miniaudio library.
///
/// It is used by the build and link hooks in the `hook/` directory.
CLibrary getCLibrary(OS targetOS) {
  final isIOS = targetOS == OS.iOS;
  return CLibrary(
    name: 'miniaudio',
    assetName: 'src/third_party/miniaudio.g.dart',
    sources: ['third_party/miniaudio.m'],
    frameworks: isIOS ? ['AVFoundation', 'AudioToolbox', 'Foundation'] : [],
    flags: isIOS ? ['-framework', 'AVFoundation', '-framework', 'AudioToolbox', '-framework', 'Foundation'] : [],
    defines: {
      if (targetOS == OS.windows) 'MA_API': '__declspec(dllexport)',
    },
  );
}
