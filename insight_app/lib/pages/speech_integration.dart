import 'package:flutter/material.dart'; //core flutter UI framework for building cross-platform widgets
import 'package:flutter_tts/flutter_tts.dart';
import 'package:insight_app/pages/speech.dart'; //convert text output into spoken audio using the device's built-in speech engine

class SpeechIntegration extends StatefulWidget {
  const SpeechIntegration({super.key});

  @override
  State<SpeechIntegration> createState() => _SpeechIntegrationState();
}

class _SpeechIntegrationState extends State<SpeechIntegration> {
  FlutterTts _flutterTts = FlutterTts();

  List<Map> _voices = [];
  Map? _currentVoice;

  int? _currentWordStart, _currentWordEnd;

  @override
  void initState() {
    super.initState();
    initTTS();
  }

  void initTTS() {
    _flutterTts.setProgressHandler((text, start, end, word) {
      setState(() {
        _currentWordStart = start;
        _currentWordEnd = end;
      });
    });
    //returns a dynamic feature (a list of maps)
    _flutterTts.getVoices.then((data) {
      try {
        _voices = List<Map>.from(data);
        setState(() {
          _voices = _voices
              .where((_voice) => _voice["name"].contains("en"))
              .toList();
          _currentVoice == _voices.first;
          setVoice(_currentVoice!);
        });
      } catch (e) {
        print(e); //print so it doesn't crash the application
      }
    });
  }

  void setVoice(Map voice) {
    _flutterTts.setVoice({"name": voice["name"], "locale": voice["locale"]});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUI(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _flutterTts.speak(TTS_INPUT);
        },
        child: const Icon(Icons.speaker_phone),
      ),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _speakerSelector(),
          RichText(
            //allows us to implement other textspans within it and for each textspan I can define the styling I want to have for that textspan
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 20,
                color: Colors.black,
              ),
              children: <TextSpan>[
                TextSpan(text: TTS_INPUT.substring(0, _currentWordStart)),
                if (_currentWordStart != null)
                  TextSpan(
                    text: TTS_INPUT.substring(
                      _currentWordStart!,
                      _currentWordEnd,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.deepOrange,
                    ),
                  ),
                if (_currentWordEnd != null)
                  TextSpan(text: TTS_INPUT.substring(_currentWordEnd!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speakerSelector() {
    return DropdownButton(
      value: _currentVoice,
      items: _voices
          .map(
            (_voice) =>
                DropdownMenuItem(value: _voice, child: Text(_voice["name"])),
          )
          .toList(),
      onChanged: (value) {},
    );
  }
}
