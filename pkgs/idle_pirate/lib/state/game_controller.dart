import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';
import 'package:mini_audio/mini_audio.dart';
import '../assets/sounds.dart';
import '../models/game_state.dart';
import '../models/item.dart';

class GameController extends ChangeNotifier {
  final Box _box;
  GameState _state = GameState();
  Timer? _timer;
  int _tickCount = 0;

  GameController({
    required this._box,
    bool startTimer = true,
    bool enableAudio = true,
  }) {
    _loadState();
    if (startTimer) {
      _startTimer();
    }
    if (enableAudio) {
      _initializeAudio();
    }
  }

  MiniAudio? _audio;

  void _initializeAudio() async {
    try {
      _audio = MiniAudio();
      await _extractAudioAssets();
    } catch (e) {
      // ignore: avoid_print
      print('Failed to initialize audio: $e');
    }
  }

  Future<void> _extractAudioAssets() async {
    final tempDir = Directory.systemTemp;

    itemSounds;
    for (final sound in Sound.used) {
      final file = File('${tempDir.path}/${sound.id}.mp3');
      if (!file.existsSync()) {
        try {
          final data = await sound.load();
          final bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await file.writeAsBytes(bytes);
        } catch (e) {
          // ignore: avoid_print
          print('Asset ${sound.id} not found or filtered out: $e');
        }
      }
    }
  }

  void _playSound(Sound sound) {
    if (_audio == null) return;
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/${sound.id}.mp3');
    if (file.existsSync()) {
      try {
        _audio!.playSound(file.path);
      } catch (e) {
        // ignore: avoid_print
        print('Failed to play sound ${sound.id}: $e');
      }
    }
  }

  GameState get state => _state;

  void _loadState() {
    final stateJson = _box.get('state') as Map?;
    if (stateJson != null) {
      _state = GameState.fromJson(Map<String, dynamic>.from(stateJson));
    } else {
      _state = GameState();
    }

    final lastSaved = _box.get('last_saved') as int?;
    if (lastSaved != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = Duration(milliseconds: now - lastSaved);
      if (elapsed.inSeconds > 0) {
        _state = _state.elapseTime(elapsed);
      }
    }
  }

  void _saveState() {
    _box.put('state', _state.toJson());
    _box.put('last_saved', DateTime.now().millisecondsSinceEpoch);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      tick();
    });
  }

  void tick() {
    final newState = _state.elapseTime(const Duration(milliseconds: 33));

    if (newState.doubloons.value > _state.doubloons.value) {
      _playSound(Sound.coin);
    }

    _state = newState;

    _tickCount++;
    if (_tickCount >= 150) {
      // 150 * 33ms = 4950ms (~5 seconds)
      _saveState();
      _tickCount = 0;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void clickChest() {
    _state = _state.clickChest();
    _playSound(Sound.coin);
    _saveState();
    notifyListeners();
  }

  void buyUpgrades(Item item, int count) {
    final newState = _state.buyUpgrades(item, count);

    if (newState != _state) {
      _state = newState;

      // Play sound based on upgrade ID
      final sound = itemSounds[item.id] ?? Sound.coin;
      _playSound(sound);

      _saveState();
      notifyListeners();
    }
  }

  void buyUpgrade(Item item) {
    buyUpgrades(item, 1);
  }
}
