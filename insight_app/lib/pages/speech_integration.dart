import 'package:flutter/material.dart'; //core flutter UI framework for building cross-platform widgets

class SpeechIntegration extends StatefulWidget {
  const SpeechIntegration({super.key});

  @override
  State<SpeechIntegration> createState() => _SpeechIntegrationState();
}

class _SpeechIntegrationState extends State<SpeechIntegration> {
  @override
  void initState() {
    super.initState();
    initTTS();
  }

  void initTTS() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
