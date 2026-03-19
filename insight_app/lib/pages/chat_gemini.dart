import 'dart:io'; //core dart libraries used to handle file system access and binary image data
import 'dart:typed_data'; //required to convert locally stored images into byte arrays for LLM upload
//imported asynchronous timing support to manage automatical speech recognition restart behaviour, this enables timer-based recovery when listening stops, forming the basis of the continuous listening pipeline
import 'dart:async'; //required to support continuous listening restart timer

//retained multimodal chat dependencies to support text, image and AI-assisted conversational interaction, these imports provide the surrounding infrastructure required for integrating voice features into the existing chat workflow
import 'package:dash_chat_2/dash_chat_2.dart'; //provides a full-features chat UI framework including message bubbles, input fields and message streaming visual updates
import 'package:flutter/material.dart'; //core flutter UI framework for building cross-platform widgets
import 'package:flutter_gemini/flutter_gemini.dart'; //gemini SDK used to interact with google's multimodal LLM (enbales both text only and image+text requests)
import 'package:image_picker/image_picker.dart'; //enables secure access to the device photo gallery for selecting stored images
//imported tts and speech recognition pakacge to support bidirectional voice interaction
import 'package:flutter_tts/flutter_tts.dart'; //convert text output into spoken audio using the device's built-in text-to-speech engine
import 'package:speech_to_text/speech_to_text.dart'
    as stt; //convert spoken user input into text using the device's speech recognition engine

//ChatGeminiPage represents the primary conversational AI interface
//it supports multimodal interaction by allowing users to submit both text and images
//the optional initialImagePath enables automated AI requests triggered on screen load
//preserved the ChatGeminiPage widget structure and optional initialImagePath parameter to maintain compaitbility with the image-driven workflow, this ensures voice enhancements do not break the existing assistive image analysis feature
class ChatGeminiPage extends StatefulWidget {
  //optional image path passed via Navigator from the camera workflow
  //this enables automated processing of newly captured images
  final String? initialImagePath;

  const ChatGeminiPage({super.key, this.initialImagePath});

  @override
  State<ChatGeminiPage> createState() => _ChatGeminiPageState();
}

//initialised the gemini client and chat user models to preserve to existing conversational architecture while extending it with voice capabilities, this keps the voice pipeline aligned with the established messaging flow
class _ChatGeminiPageState extends State<ChatGeminiPage> {
  final Gemini gemini = Gemini
      .instance; //gemini client instance used to manage API requests and streaming responses
  List<ChatMessage> messages =
      []; //local in memory chat history used to render messages in DashChat UI
  ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "CurrentUser",
  ); //represents the human user in the chat UI
  ChatUser chatGemini = ChatUser(
    id: "1",
    firstName: "GeminiChat",
  ); //represents the gemini AI agent in the chat UI

  //text to speech engine
  //initialised the text-to-speech engine for spoken AI feedback, this enables generated responses to be delivered in an accessible audio format for visually impaired users
  final FlutterTts flutterTts = FlutterTts();

  //speech to text engine
  //initialise dthe pseech recognition engine for capturing microphone input and converting spoken commands into text, this provides the core mechanism require for voice-driven interaction
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isSpeaking = false; //track speaking state to prevent feedback loop
  bool _speechEnabled = false; //track if speech system is ready
  bool _processingCommand = false; //prevent duplicate commands
  Timer? _restartTimer; //timer to restart listening automatically

  @override
  void initState() {
    super.initState();
    _setupTts();
    _initSpeech();

    if (widget.initialImagePath != null) {
      //constructs a ChatMessage containing both a default prompt and the captured image as multimodal input for gemini
      final chatMessage = ChatMessage(
        text:
            "You are an assistive AI for a visually impaired user. Describe the scene focusing on obstacles, distances and navigation. For example: 'A chair is two metres ahead, a table is to your left'",
        user: currentUser,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: widget.initialImagePath!,
            fileName: "",
            type: MediaType.image,
          ),
        ],
      );
      _onSend(
        chatMessage,
      ); //automatically sends the constructed message to gemini on screen load
    }
  }

  //text to speech configuration
  void _setupTts() {
    flutterTts.setSpeechRate(0.45);
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);
    //stop listening when the app starts speaking to avoid feedback loops
    flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _stopListening();
    });
    //restart listening after gemini speaks
    flutterTts.setCompletionHandler(() {
      _isSpeaking = true;
      _scheduleRestartListening(); //automatically restart listening after speech finishes
    });
    //also recover listening if speech fails
    flutterTts.setErrorHandler((message) {
      _isSpeaking = false;
      _scheduleRestartListening();
    });
    //also recover listening if speech is cancelled
    flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _scheduleRestartListening();
    });
  }

  //text to speech function
  Future<void> speak(String text) async {
    //remove markdown formatting symbols before speech
    final cleanedText = text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'#'), '')
        .replaceAll(RegExp(r'_'), '')
        .replaceAll('’', "'");
    //prevents overlapping speech by explicitly stopping any current text-to-speech playback before speaking a new response, this avoids clutter or repeated audio output
    await flutterTts.stop();
    await flutterTts.speak(cleanedText);
  }

  //initialises speech recognition with continuous restart behaviour
  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _scheduleRestartListening();
        }
      },
      onError: (error) {
        _scheduleRestartListening();
      },
    );
    if (_speechEnabled) {
      _startListening();
    }
  }

  //schedules a delayed restart to avoid rapid recognition restarts
  void _scheduleRestartListening() {
    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(milliseconds: 700), () {
      if (!_isListening && !_isSpeaking) {
        _startListening();
      }
    });
  }

  //starts speech recognition in dictation mode
  Future<void> _startListening() async {
    if (!_speechEnabled || _isListening || _isSpeaking) return;

    final started = await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(minutes: 1),
    )

      bool available = await _speech.initialize();

      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          listenMode: stt.ListenMode.dictation,
          onResult: (result) {
            if (result.finalResult) {
              String spokenText = result.recognizedWords.toLowerCase();
              //wake word detection
              if (spokenText.contains("hey insight")) {
                String cleanedCommand = spokenText
                    .replaceAll("hey insight", "")
                    .trim();
                if (cleanedCommand.isNotEmpty) {
                  ChatMessage chatMessage = ChatMessage(
                    text: cleanedCommand,
                    user: currentUser,
                    createdAt: DateTime.now(),
                  );
                  _onSend(chatMessage);
                }
              }
            }
          },
        );
      }
    }
  }

  //central message handling function
  //responsible for:
  // - updating UI state
  // - extracting text and image data
  // - sending multimodal requests to gemini
  // - handling streamed partial responses
  void _onSend(ChatMessage chatMessage) {
    setState(() {
      //immediately update UI with the users outgoing message
      messages = [chatMessage, ...messages];
    });
    try {
      final question = chatMessage.text;
      List<Uint8List>?
      images; //optional list of image byte arrays for multimodal gemini input
      //if the message includes an image, load and convert it to bytes
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }

      //initiates a streaming gemini request
      //this allows partial responses to be displayed in real-time, improving receieved responsiveness and user experience
      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        String response = "";
        //iterates over streamed content parts returned by gemini
        //each part may contain partial text tokens
        if (event.content?.parts != null) {
          for (final part in event.content!.parts!) {
            //ensures only text parts are processed
            if (part is TextPart) {
              final text = part.text;
              //accumulates streamed tokens into a continuous response string
              if (text.isNotEmpty) {
                if (response.isNotEmpty &&
                    !response.endsWith(' ') &&
                    !text.startsWith(' ')) {
                  response += ' ';
                }
                response += text;
              }
            }
          }
        }
        //prevents UI updates for empty or whitespace-only chunks
        if (response.trim().isEmpty) {
          return;
        }
        //if the last message is already a gemini message, append streamed tokens to the existing bubble
        if (lastMessage != null && lastMessage.user.id == chatGemini.id) {
          lastMessage = messages.removeAt(0);
          //ensures clean spacing when appending streamed text
          if (!lastMessage.text.endsWith(' ') && !response.startsWith(' ')) {
            lastMessage.text += ' ';
          }
          lastMessage.text += response;

          //updates UI with appended streamed content
          setState(() {
            messages = [lastMessage!, ...messages];
          });
          //speak updated response
          speak(lastMessage.text);
        } else {
          //creates a new gemini message bubble for the first streamed chunk
          final responseMessage = ChatMessage(
            text: response,
            user: chatGemini,
            createdAt: DateTime.now(),
          );
          setState(() {
            messages = [responseMessage, ...messages];
          });
          //speak new response
          speak(response);
        }
      });
    } catch (e, stack) {
      //robust error logging for debugging gemini API or file IO issues
      print("Gemini error: $e");
      print(stack);
    }
  }

  //allows users to manually select an image from the device gallery
  //this uspports secondary multimodal workflows in addition to live camera capture
  void _sendImageMessage() {
    ImagePicker().pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        //constructs a multimodal chat message using the selected image
        ChatMessage chatMessage = ChatMessage(
          text:
              "You are an assistive AI for a visually impaired user. Describe the scene focusing on obstacles, distances and navigation. For example: 'A chair is two metres ahead, a table is to your left'",
          user: currentUser,
          createdAt: DateTime.now(),
          medias: [
            ChatMedia(url: image.path, fileName: "", type: MediaType.image),
          ],
        );
        //sends the image message through the same unified pipeline
        _onSend(chatMessage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar provides consistent navigation context for the chat screen
      appBar: AppBar(title: Text('Chat Gemini'), centerTitle: true),
      //main chat UI rendered via DashChat widget
      body: _buildChatUi(),
    );
  }

  //encapsulates DashChat configuration
  //separating this into a method improves readability and maintainability
  Widget _buildChatUi() {
    return DashChat(
      //adds an image picker button to the chat input field
      inputOptions: InputOptions(
        trailing: [
          IconButton(onPressed: _sendImageMessage, icon: Icon(Icons.image)),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _startListening,
          ),
        ],
      ),
      currentUser:
          currentUser, //idenitfies which messages belong to the current user
      onSend: _onSend, //binds send action to unified message handling logic
      messages:
          messages, //supplies current in-memory message list to the chat UI
    );
  }
}
