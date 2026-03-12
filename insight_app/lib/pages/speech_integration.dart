import 'package:flutter/material.dart'; //core flutter UI framework for building cross-platform widgets
import 'package:flutter_tts/flutter_tts.dart'; //convert text output into spoken audio using the device's built-in speech engine

class SpeechIntegration extends StatefulWidget {
  const SpeechIntegration({super.key});

  @override
  State<SpeechIntegration> createState() => _SpeechIntegrationState();
}

class _SpeechIntegrationState extends State<SpeechIntegration> {
  FlutterTts _flutterTts = FlutterTts();

  Map? _currentVoice;

  @override
  void initState() {
    super.initState();
    initTTS();
  }

  void initTTS() {
    //returns a dynamic feature (a list of maps)
    _flutterTts.getVoices.then((data) {
      try {
        List<Map> _voices = List<Map>.from(data);
        _voices = _voices
            .where((_voice) => _voice["name"].contains("en"))
            .toList();
        print(_voices);
        setState(() {});
      } catch (e) {
        print(e); //print so it doesn't crash the application
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
