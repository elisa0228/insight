//this page is the home screen of my app, it's the first thing the user sees, it gives them two option - either scan environemt using the camera or open the chatbot assistant
//the design focuses on accessibility first, not just functionality

//imports the core Flutter UI framework used to build widgets such as scaffold, text, column
import 'package:flutter/material.dart';
//imports the text-to-speech package which allows the app to speak text out loud
import 'package:flutter_tts/flutter_tts.dart';
//imports the camera screen where users can capture images
import 'camera_picture.dart';
//imports the Gemini chatbot screen for AI interaction
import 'chat_gemini.dart';

//this is a the main menu page of the application
//it is a stateful widget because it manages dynamic behaviour
//it speaks to the user using text-to-speech, so it needs to run code when the page loads
class NewMenuPage extends StatefulWidget {
  const NewMenuPage({super.key});

  @override
  State<NewMenuPage> createState() => _NewMenuPageState();
}

//this is the state class where all logic for the menu page is handled
class _NewMenuPageState extends State<NewMenuPage> {
  //creates an instance of the text-to-speech engine
  //this is used throughout the page to provide spoken feedback to the user
  //created the voice system that lets the app talk out loud
  final FlutterTts flutterTts = FlutterTts();

  //this function runs once when the page is first created
  //it is used to initialise settings and trigger the welcome speech
  //when the app open, this function runs automatically, used it to set up the voice and give instructions to the user
  @override
  void initState() {
    super.initState();
    //sets the speed of speech (lower value = slower speech for accessibility, hence easier to understand)
    flutterTts.setSpeechRate(0.45);

    //delays execution slightly to ensure the UI has fully loaded before speaking
    //added a short delay so the app doesn't start speaking before the screen fully loads
    //delayed so it doesn't talk before the UI loads
    Future.delayed(const Duration(milliseconds: 600), () async {
      //ensures speech completes fully before the next sentence starts
      await flutterTts.awaitSpeakCompletion(true);

      //gives the user spoken instructions so they know what to do without needing to see the screen
      //welcome message for the user
      await speak("Welcome to InSight,");
      //short pause for clarity between sentences
      await Future.delayed(const Duration(milliseconds: 400));
      //instruction for top half of screen (camera)
      await speak("Tap the top card to scan your environment,");
      //short pause for clarity between sentences
      await Future.delayed(const Duration(milliseconds: 300));
      //instruction for bottom half of the screen (chatbot)
      await speak("Tap the bottom card to open the AI assistant,");
    });
  }

  //reusable, helper function to convert any text into speech
  //this centralises all speech behaviour in one place
  //instead of repeating code, this one function handles all speech
  Future<void> speak(String text) async {
    //stops any currently playing speech to avoid overlap
    await flutterTts.stop();
    //speak the provided text out loud
    await flutterTts.speak(text);
  }

  //handles navigation between screens
  //also provides audio feedback before navigating
  //function decided where the users goes when they tap the card
  void _navigate(String screen) async {
    //checks if the user selected the camera option
    //if the users taps the top card, the app speaks and then opens the camera page
    if (screen == "camera") {
      //informs the user that navigation is happening
      await speak("Opening camera preview page");
      //navigates to the camera page using flutters navigator
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraPage()),
      );
      //if they tap the bottom card, it opens the chatbot instead
    } else {
      //informs the user that the chatbot is opening
      await speak("Opening AI assistant page");
      //navigates to the chatbot page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatGeminiPage()),
      );
    }
  }

  //build the user interface of the menu page
  //the layout is designned to be simple and accessible, especially for visually impaired users
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //sets a dark background colour for accessibility and contrast
      backgroundColor: const Color(0xFF030712), // dark background
      //safe area ensures UI elements do not overlap system UI (like notch or status bar)
      body: SafeArea(
        child: Column(
          children: [
            //header section (logo + app name)
            //at the top, it shoes the app name and an icon to indicate voice features
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  //icon container with graident background
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    //speaker icon indicating voice-based functionality
                    child: const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  //app title and subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      //app name
                      Text(
                        "Insight",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      //instruction subtitle
                      Text(
                        'Tap a card to begin',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //main card section (interactive buttons)
            //the top half of the screen is for scanning the environment and the bottom half is for the chatbot
            //the screen screen is split into two large buttons so its easy to tap anywhere
            //big buttons (cards) are used to make tapping easier and reduce precision required
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    //camera card (top half of screen)
                    //this card opens the camera so the user can take a picture and analyse their surroundings
                    Expanded(
                      child: GestureDetector(
                        //detects user tap and triggers navigation
                        onTap: () => _navigate("camera"),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(24),
                          //visual styling using gradient and shadows
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          //layout for icon and text
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //top row (icon + indicator)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                  //decorative circle
                                  Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              //text content
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Scan Environment",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Use camera to analyze your surroundings",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    //chatbot card (bottom half of screen)
                    //this opens the assistant where the users can ask questions using voice or text
                    Expanded(
                      child: GestureDetector(
                        //triggers chatbot navigation
                        onTap: () => _navigate("chat"),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(24),
                          //purple gradient styling
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //icon row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                  Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              //text content
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "AI Assistant",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Ask questions and get help",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    //intructions card (extra guidance ofr users and helpers)
                    //added a small instruction section for extra guidanc for helpers, but the main guidance is spoken out loud
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Instructions",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "• Tap the top card to scan your environment\n"
                            "• Tap the bottom card to open the AI assistant\n"
                            "• The app will speak actions aloud",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
