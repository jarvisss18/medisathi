import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.45); // Slower rate for elderly accessibility
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> speak(String text, {String langCode = 'en'}) async {
    try {
      await init();
      String locale = 'en-IN';
      if (langCode == 'hi') locale = 'hi-IN';
      if (langCode == 'mr') locale = 'mr-IN';

      await _flutterTts.setLanguage(locale);
      await _flutterTts.speak(text);
    } catch (_) {
      // Graceful fallback to default engine
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.speak(text);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
