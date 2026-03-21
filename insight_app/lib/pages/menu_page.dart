import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; //imports flutter matieral components to build a standard Android/iOS styled UI widgets
import 'camera_picture.dart'; //imports the CameraPage which handles real-time camera preview and image capture
import 'chat_gemini.dart'; //imports the ChatGeminiPage which manages the LLM (Gemini) chatbot and image-to-AI interaction
import 'package:speech_to_text/speech_to_text.dart'
    as stt; //convert spoken user input into text using the device's speech recognition engine

//MenuPage represents the main navigation hub of the application
//it allows the user to choose between two primary application workflows:
//option one: capturing an image using the device camera
//option two: interacting directly with the Gemini chatbot
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  //void _restartListening() async {
  //await _speech.stop();

  //setState(() {
  //_isListening = false;
  //});

  //Future.delayed(const Duration(milliseconds: 1000), () {
  //_startListening();
  //});
  //}

  //initialise speech recognition
  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        debugPrint("STATUS: $status");

        if (!mounted) return;

        if (status == "done" || status == "not listening") {
          _restartListening();
        }
      },
      onError: (error) {
        debugPrint("ERROR: $error");
        _restartListening();
      },
    );

    if (_speechEnabled) {
      _startListening();
    }
  }

  //start listening automatically
  Future<void> _startListening() async {
    if (!_speechEnabled || _isListening) return;

    debugPrint("START LISTEING");

    await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        if (!result.finalResult) return;

        final spokenText = result.recognizedWords.toLowerCase();
        debugPrint("heard: $spokenText");

        _handleCommand(spokenText);
      },
    );
    if (!mounted) return;

    setState(() {
      _isListening = true;
    });
  }

  //handle voice commands
  void _handleCommand(String spokenText) {
    //must contain wake word
    if (!(spokenText.contains("hey insight") ||
        spokenText.contains("heyinsight"))) {
      _restartListening();
      return;
    }
    final command = spokenText
        .replaceAll("hey insight", "")
        .replaceAll("heyinsight", "")
        .trim();

    debugPrint("COMMAND: $command");

    //navigation
    if (command.contains("camera")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraPage()),
      );
    } else if (command.contains("chat") || command.contains("bot")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatGeminiPage()),
      );
    }

    _restartListening();
  }

  //restart listening
  void _restartListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  //builds the static UI for the menu screen
  //StatelessWidget is used because this screen does not manage or mutate any internal state
  //it simply provides navigation controls to other stateful feature screens
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar provides a consistent top navigation bar across the application
      //displaying the application name for branding and user orientation
      appBar: AppBar(title: const Text("Insight")),

      body: Column(
        //vertically centres menu buttons for accessibility and ease of use, particularly important for visually impaired or assistive users
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //listening inidicator
          Text(
            _isListening ? "Listening..." : "Voice inactive",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),

          //primary action button for camera-based visual analysis workflow
          ElevatedButton(
            //clearly labelled to indicate that this option opens the camera
            child: const Text("Take Picture"),
            //when pressed, it navigates to the CameraPage using flutters navigator
            //Navigator.push creates a new route on the navigation stack, allowing the user to return to the menu using the back button
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraPage()),
              );
            },
          ),

          //adds vertical spacing between button for improved UI clarity
          const SizedBox(height: 20),

          //secondary action button for direct chatbot interaction workflow
          ElevatedButton(
            //clearly labelled to indicate that this option opens the AI chatbot
            child: const Text("chatbot"),
            //navigates to the ChatGeminiPage
            //this enables users to interact with Gemini without capturing an image, supporting both text-based and optional image-based AI interactions
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatGeminiPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
