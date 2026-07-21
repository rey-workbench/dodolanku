import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Future<void> playScanBeep() async {
    try {
      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }
      await _player.play(AssetSource('audio/scan_beep.aac'), volume: 1.0);
    } catch (e) {
      if (kDebugMode) {
        print('AudioService Error: $e');
      }
    }
  }
}
