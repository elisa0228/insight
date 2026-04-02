//the main AI interaction screen, allows the user to send text, voice or images to the gemini model, app processes the input, send it to the AI and streams the response back in real-time
//the response is dis played on the screen and also spoken aloud using tts, making it accessible for visually impaires users, also supports continuous listening so the user can interact hands-free using voice commands

//imports file handling tools so the app can open image files saved on the phone
import 'dart:io';

//imports byte array support so images can be converted into raw data for Gemini
import 'dart:typed_data';

//imported asynchronous timing support to manage automatical speech recognition restart behaviour, this enables timer-based recovery when listening stops, forming the basis of the continuous listening pipeline
import 'dart:async'; //required to support continuous listening restart timer after short delays

//retained multimodal chat dependencies to support text, image and AI-assisted conversational interaction, these imports provide the surrounding infrastructure required for integrating voice features into the existing chat workflow
import 'package:dash_chat_2/dash_chat_2.dart'; //provides a full-features chat UI framework including message bubbles, input areas and message layout

//core flutter UI framework for building cross-platform widgets, building screens, buttons, layouts, texts and icons
import 'package:flutter/material.dart';

//imports the gemini package so the app can send questions and images to Google's AI model
import 'package:flutter_gemini/flutter_gemini.dart';

//enables secure access to the device photo gallery, imports the allery picker so the user can choose an image from their device
import 'package:image_picker/image_picker.dart';

//imported tts and speech recognition pakacge to support bidirectional voice interaction
import 'package:flutter_tts/flutter_tts.dart'; //convert text output into spoken audio using the device's built-in text-to-speech engine

//convert spoken user input into text using the device's speech recognition engine
import 'package:speech_to_text/speech_to_text.dart' as stt;

//ChatGeminiPage represents the primary conversational AI interface
//it supports multimodal interaction by allowing users to submit both text and images
//the optional initialImagePath enables automated AI requests triggered on screen load
//it is stateful because the screen changes over time when messages are sent, AI replied arrive and speech starts/stops
class ChatGeminiPage extends StatefulWidget {
  //this stores the path of an image if the user arrived here from the camera page
  //it is optional because sometimes the user opens the chatbot directly with no image
  //this enables automated processing of newly captured images
  //the app does not require an image every time
  final String? initialImagePath;

  //this tells the app whether the chatbot page was opened from the camera page
  //this is useful for deciding what the back button should say out loud
  final bool fromCamera;

  //constructor for the widget
  //super.key is the normal Flutter widget key
  //initialImagePath is optional
  //fromCamera by default the app assume the user did not come from the camera unless explicitely said they did
  const ChatGeminiPage({
    super.key,
    this.initialImagePath,
    this.fromCamera = false,
  });

  //creates the mutable state object that hold the logic for this screen
  @override
  State<ChatGeminiPage> createState() => _ChatGeminiPageState();
}

//this class stores all the logic, variables and UI updates for the chatbot page
class _ChatGeminiPageState extends State<ChatGeminiPage> {
  final Gemini gemini = Gemini
      .instance; //creates a gemini instance so this page can send requests to the AI model
  List<ChatMessage> messages =
      []; //stores the chat history shown on screen, every time the user or AI sends a message, it gets added here

  //DashChat needs a user object so it knows which messages belong to the person using the app
  ChatUser currentUser = ChatUser(
    id: "0", //unique ID for the user
    firstName: "CurrentUser", //display name for the user
  ); //defines the human user in the chat UI

  //DashChat uses this to show AI messages separately from human messages
  ChatUser chatGemini = ChatUser(
    id: "1", //unique ID for the AI
    firstName: "GeminiChat", //display name for the AI
  ); //defines the gemini AI agent in the chat UI

  //creates the text-to-speech engine
  //initialised the text-to-speech engine for spoken AI feedback, this enables generated responses to be delivered in an accessible audio format for visually impaired users
  //allows the app to speak messages such as navigation feedback and AI responses
  final FlutterTts flutterTts = FlutterTts();

  //creates the speech-to-text engine
  //initialised the speech recognition engine for capturing microphone input and converting spoken commands into text, this provides the core mechanism require for voice-driven interaction
  //allows the app to listen to the user's voice and turn it into text
  final stt.SpeechToText _speech = stt.SpeechToText();

  //tracks whether the app is currently listening to the user's voice
  bool _isListening = false;
  //track whether the app is currently speaking out loud
  //this helps avoid the app listening to its own voice and causing a feedback loop
  bool _isSpeaking = false;
  //tracks whether speech recognition has been successfully initialised
  //if false, the app should not try to start listening
  bool _speechEnabled = false;
  //used to stop the app from processing multiple voice commands at the same time
  //this prevents duplicate sends or repeated actions
  bool _processingCommand = false;
  //timer used to restart listening after speech ends or recognition stops
  Timer? _restartTimer;

  //stores the last image that was send to gemini
  //this is the important memory feature, stores last image so AI remembers it therefore lets the AI answer follow-up questions about the same picture
  Uint8List? _lastImage;

  //this function runs once when the page is first openeds
  //it is used to initialise text-to-speech, speech-to-text and send the image automatically if one was passed in
  @override
  void initState() {
    super.initState(); //always call the parent initState first
    _setupTts(); //sets up the text-to-speech behaviour
    _initSpeech(); //sets up speech recognition behaviour

    //if an image path was passed into this page, that means the user came from the cmaera page
    if (widget.initialImagePath != null) {
      //created a chat message containing the default assistive prompt and the captures image
      final chatMessage = ChatMessage(
        text:
            "You are an assistive AI for a visually impaired user. Describe the scene focusing on obstacles, distances and navigation. For example: 'A chair is two metres ahead, a table is to your left'",
        user:
            currentUser, //this message is treated as if it came from the human user
        createdAt: DateTime.now(), //timestamp for the message
        medias: [
          //attaches the captures image to the message
          ChatMedia(
            url: widget.initialImagePath!, //file path of the image
            fileName: "", //filename left empty because it is not essential here
            type: MediaType
                .image, //tells DashChat that this media item is an image
          ),
        ],
      );
      //sends the image message immediately so gemini can analyse the picture as soon as the page opens
      _onSend(
        chatMessage,
      ); //automatically sends the constructed message to gemini on screen load
    }
  }

  //this function sets up how text-to-speech should behave
  //it controls the voice settings and what should happen whens speech starts or ends
  void _setupTts() {
    flutterTts.awaitSpeakCompletion(
      true,
    ); //tells Flutter to wait until speech is full finish before moving on
    flutterTts.setSpeechRate(
      0.45,
    ); //makes the pseech slower and easier to understand
    flutterTts.setPitch(1.0); //keeps the pitch at a natural level
    flutterTts.setVolume(1.0); //sets volume to maximum

    //stop listening when the app starts speaking to avoid feedback loops
    //runs when app starts speaking
    flutterTts.setStartHandler(() {
      if (!mounted)
        return; //make sure the widget still exists before changing state
      setState(() {
        _isSpeaking = true; //records that the app is crrently speaking
      });
      _stopListening(); //stops the microphone so the app doesn not hear its own voice
    });

    //restart listening after gemini speaks
    //runs when the app finishes speaking
    flutterTts.setCompletionHandler(() {
      if (!mounted) return; //make sure the widget still exists
      setState(() {
        _isSpeaking = false; //records that speech has finished
      });
      _scheduleRestartListening(); //automatically restart listening after speech finishes
    });

    //also recover listening if speech fails
    //this runs if text-to-speech produces an error
    flutterTts.setErrorHandler((message) {
      if (!mounted)
        return; //avoids updating speech state is page no longer exists
      setState(() {
        _isSpeaking = false; //make sure speaking flag is reset
      });
      _scheduleRestartListening(); //tries to recover by restarting listening
    });
    //also recover listening if speech is cancelled
    //this runs if speech is cancelled
    flutterTts.setCancelHandler(() {
      if (!mounted) return; //avoids invalid state updates
      setState(() {
        _isSpeaking = false; //resets speaking flag
      });
      _scheduleRestartListening(); //restarts listening after cancellation
    });
  }

  //this function takes any text string and makes the app speak it out loud
  Future<void> speak(String text) async {
    //this cleans the text before speaking
    //the purpose is to stop markdown symbols like * or # from being read out loud awkwardly
    final cleanedText = text
        .replaceAll(RegExp(r'\*\*'), '') //removes bold markdown markers
        .replaceAll(RegExp(r'\*'), '') //removes single star markers
        .replaceAll(RegExp(r'#'), '') //removes heading markers
        .replaceAll(
          RegExp(r'###'),
          '',
        ) //removes triple heading markers if present
        .replaceAll(RegExp(r'_'), '') //removes underscore markers
        .replaceAll(
          '’',
          "'",
        ); //replaces curly apostrophes with plain apostrophes

    await flutterTts
        .stop(); //stops any speech already playing so audio does not overlap
    await flutterTts.speak(cleanedText); //speaks the cleaned text
  }

  //this function initialises speech recognition
  //it prepares the app to listen to the users voice
  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      //this callback runs whenever the speech recogniser changes status
      onStatus: (status) {
        debugPrint(
          "speech status: $status",
        ); //prints status for debugging in terminal

        if (!mounted) return; //do nothing if widget no longer exists

        //if listening ends or recogniser stops, reset flag and restart listening
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false; //records that listening has stopped
          });
          _scheduleRestartListening(); //starts listening again after a short delay
        }
      },
      //this classback runs if speech recognition produces an error
      onError: (error) {
        debugPrint(
          "speech error: $error",
        ); //prints error in terminal for debugging

        if (!mounted) return; //do nothing if widget no longer exists

        setState(() {
          _isListening = false; //resets listening flag if an error happens
        });
        _scheduleRestartListening(); //tries to recover by restarting listening
      },
    );
    debugPrint(
      "speech enabled: $_speechEnabled",
    ); //prints whether speech initialised successfully

    //if speech recognition is ready, start listening immediately
    if (_speechEnabled) {
      _startListening();
    }
  }

  //this function schedules listening to restart after a short delay
  //this avoids restart listening too aggressively and helps speech flow more smoothly
  void _scheduleRestartListening() {
    _restartTimer
        ?.cancel(); //cancels any old timer so we don't restart multiple times
    _restartTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return; //stop if widget no longer exists

      //only restart if app is not already listening, not speaking, not busy and speech is enabled
      if (!_isListening &&
          !_isSpeaking &&
          !_processingCommand &&
          _speechEnabled) {
        debugPrint(
          "restart listening...",
        ); //debug print to show restart behaviour
        _startListening(); //starts listening again
      }
    });
  }

  //this function starts speech recognition
  //it listens for the users voice and turns it into text
  Future<void> _startListening() async {
    //stop immediately if listening should not start
    if (!_speechEnabled || _isListening || _isSpeaking || _processingCommand) {
      return;
    }
    if (!mounted) return; //prevents state changes if widget no longer exists
    setState(() {
      _isListening = true; //records that listening has started
    });

    debugPrint("starting listening..."); //prints debug message in terminal

    await _speech.listen(
      listenMode: stt.ListenMode.dictation, //allows more natural speech input
      partialResults:
          true, //lets recogniser produce partial updates while user is speaking
      pauseFor: const Duration(
        seconds: 3,
      ), //stops listening if user pauses for too long
      listenFor: const Duration(
        minutes: 1,
      ), //maximum listen duration before recognisr stops
      onResult: (result) async {
        //ignore unfinishes speech or overlapping commands
        if (!result.finalResult || _processingCommand) return;

        final spokenText = result.recognizedWords
            .toLowerCase()
            .trim(); //converts recognised speech to lowercase text
        debugPrint("heard: $spokenText"); //prints what was heard into terminal

        String command =
            spokenText; //by default, the whole spoken sentence becomes the command
        bool usedWakeWord =
            false; //tracks whether the phrase "hey insight" was used
        //if wake word is present, remove it from the command
        if (spokenText.contains("hey insight")) {
          command = spokenText
              .replaceAll("hey insight", "")
              .trim(); //removes wake word from the command
          usedWakeWord = true; //remembers that the wake word was used
        }

        if (command.isEmpty) return; //do nothing if no actual command remains
        _processingCommand =
            true; //blocks other commands until this one is finished

        //if used wake word, stop listening and respond with "yes?"
        if (usedWakeWord) {
          await _stopListening(); //stops listening before speaking
          await speak("yes?"); //voice acknowledgement like a virtual assistant
        }

        //convert spoken command into a chat message from the user
        final chatMessage = ChatMessage(
          text: command, //spoken words become the message text
          user: currentUser, //message belongs to the human user
          createdAt:
              DateTime.now(), //timestamp for when the message was created
        );
        _onSend(chatMessage); //send the spoken message to gemini
        _processingCommand = false; //unlock command processing after sending
      },
    );
  }

  //this function stops speech recognition and clears any pending restart timer
  Future<void> _stopListening() async {
    _restartTimer?.cancel(); //stops any scheduled restart

    if (_speech.isListening) {
      await _speech.stop(); //actually stops microphone listening if active
    }
    if (!mounted) return; //do nothing if widget no longer exists

    setState(() {
      _isListening = false; //updates UI state to show listening has stopped
    });
  }

  //this is the main function that handles every outgoing message
  //it is used for normal text, spoken text and image messages
  //central message handling function
  //responsible for:
  // - updating UI state
  // - extracting text and image data
  // - sending multimodal requests to gemini
  // - handling streamed partial responses
  void _onSend(ChatMessage chatMessage) {
    setState(() {
      messages = [
        chatMessage,
        ...messages,
      ]; //immediately shows the users message at the top of the chat list
    });
    try {
      final question = chatMessage.text; //stores the text part of the message
      List<Uint8List>?
      images; //will hold image data if an image needs to be sent to gemini
      //if the current message contains an image, load it and also save it as the last remembered image
      if (chatMessage.medias?.isNotEmpty ?? false) {
        _lastImage = File(
          chatMessage.medias!.first.url,
        ).readAsBytesSync(); //reads the image files into raw bytes and stores it in memory
        images = [_lastImage!]; //sends this new image to gemini
      } else if (_lastImage != null) {
        //if this message does not contain a new image, but a previous image exists, reuse it
        images = [
          _lastImage!,
        ]; //this is the memory feature that lets follow-up questions use the same picture
      }

      //initiates a streaming gemini request
      //this allows partial responses to be displayed in real-time, improving receieved responsiveness and user experience
      //sends the message and optional image to gemini as a streming request
      gemini
          .streamGenerateContent(question, images: images)
          .listen(
            (event) {
              ChatMessage? lastMessage = messages
                  .firstOrNull; //checks the latest message currently in the chat
              String response = ""; //stores AI text as it streams in
              //if gemini returns content parts, go through them one by one
              if (event.content?.parts != null) {
                for (final part in event.content!.parts!) {
                  //only handle text parts
                  if (part is TextPart) {
                    final text = part.text; //extracts the streamed text token
                    //if the text is not empty, append it into the response string
                    if (text.isNotEmpty) {
                      if (response.isNotEmpty &&
                          !response.endsWith(' ') &&
                          !text.startsWith(' ')) {
                        response += ' '; //adds a space if needed for readbility
                      }
                      response += text; //appends the current text chunk
                    }
                  }
                }
              }
              //prevents UI updates for empty or whitespace-only chunks
              if (response.trim().isEmpty) {
                //ignore empty AI chunks
                return;
              }
              //if the last/newest message is already a gemini message, append more streamed text into it
              if (lastMessage != null && lastMessage.user.id == chatGemini.id) {
                lastMessage = messages.removeAt(
                  0,
                ); //remove the current top AI message so it can be updated
                //ensures clean spacing when appending streamed text
                if (!lastMessage.text.endsWith(' ') &&
                    !response.startsWith(' ')) {
                  lastMessage.text +=
                      ' '; //add space if needed before appending
                }
                lastMessage.text +=
                    response; //add new streamed text to same AI bubble

                //updates UI with appended streamed content
                setState(() {
                  messages = [
                    lastMessage!,
                    ...messages,
                  ]; //put updated AI message back at top of list
                });
              } else {
                //creates a new gemini message bubble for the first streamed chunk
                //if there is no existing AI message to append to, create a new one
                final responseMessage = ChatMessage(
                  text: response, //text from gemini
                  user: chatGemini, //mark it as AI
                  createdAt: DateTime.now(), //timestamp for AI response
                );
                setState(() {
                  messages = [
                    responseMessage,
                    ...messages,
                  ]; //insert AI response into chat
                });
              }
            },
            //when gemini finishes streaming, speak the final AI response out loud
            onDone: () async {
              final aiMessage =
                  messages.isNotEmpty && messages.first.user.id == chatGemini.id
                  ? messages
                        .first
                        .text //if latest message belongs to gemini, get its text
                  : "";
              if (aiMessage.trim().isNotEmpty) {
                await speak(aiMessage); //speak the full AI answer
              } else {
                _scheduleRestartListening(); //if for some reason nothing spoken, restart listening
              }
            },
            //if gemini returns an error, log it and restart listening
            onError: (error) {
              print("Gemini error: $error"); //print AI error in console
              _scheduleRestartListening(); //recover by restart listening
            },
          );
    } catch (e, stack) {
      //robust error logging for debugging gemini API or file IO issues
      print("Gemini error: $e"); //print general error
      print(stack); //print stack trace to help debugging
      _scheduleRestartListening(); //restart listening if something fails
    }
  }

  //this function lets the user manually select an image from the gallery
  //this supports secondary multimodal workflow besides taking a live camera capture
  void _sendImageMessage() {
    ImagePicker().pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        //creates a new image-based chat message using the same assistie prompt
        final chatMessage = ChatMessage(
          text:
              "You are an assistive AI for a visually impaired user. Describe the scene focusing on obstacles, distances and navigation. For example: 'A chair is two metres ahead, a table is to your left'",
          user: currentUser, //image message belongs to the user
          createdAt: DateTime.now(), //timestamp for the message
          medias: [
            ChatMedia(
              url: image.path, //path of selected image
              fileName: "", //filename not essential here
              type: MediaType.image,
            ), //marks it as an image
          ],
        );
        //sends the image message through the same unified pipeline
        _onSend(chatMessage); //send selected image to gemini
      }
    });
  }

  //this runs when the page is being removed from memory
  //it is used to clean up resources so there are no leaks or background activity
  @override
  void dispose() {
    _restartTimer?.cancel(); //cancel any pending restart timer
    flutterTts.stop(); //stop speech output
    _speech.stop(); //stop speech recognition
    super.dispose(); //call parent dispose
  }

  //builds the main screen layout for the chatbot page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //app bar provides consistent navigation context for the chat screen
      //app bar at the top of the screen
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), //back arrow icon
          onPressed: () async {
            //if page was opened from camera, speak that we are returning to picture preview
            if (widget.fromCamera) {
              await speak("Navigating back to camera preview");
            } else {
              //otherwise say we are going back to home page
              await speak("Navigating back to home page");
            }
            Navigator.pop(context); //go back to previous page
          },
        ),
        title: const Text('Chat Gemini'), //page title shown in app bar
        centerTitle: true, //keep title centred
      ),
      //main body of the screen is the chat UI
      body: _buildChatUi(),
    );
  }

  //builds the DashChat widget that shows messages and input area
  //encapsulates DashChat configuration
  //separating this into a method improves readability and maintainability
  Widget _buildChatUi() {
    return DashChat(
      currentUser:
          currentUser, //tells DashChat which messages belong to the human user
      onSend: _onSend, //connects the send button to the _onSend function
      messages:
          messages, //gives DashChat the full list of current messages to display
      inputOptions: InputOptions(
        trailing: [
          //image picker button on the right side of the input area
          IconButton(
            onPressed:
                _sendImageMessage, //opens gallery and sends selected image
            icon: Icon(Icons.image), //image icon shown in input bar
          ),
        ],
      ),
    );
  }
}
