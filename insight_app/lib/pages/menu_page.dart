import 'package:flutter/material.dart'; //imports flutter matieral components to build a standard Android/iOS styled UI widgets
import 'camera_picture.dart'; //imports the CameraPage which handles real-time camera preview and image capture
import 'chat_gemini.dart'; //imports the ChatGeminiPage which manages the LLM (Gemini) chatbot and image-to-AI interaction

//MenuPage represents the main navigation hub of the application
//it allows the user to choose between two primary application workflows:
//option one: capturing an image using the device camera
//option two: interacting directly with the Gemini chatbot
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  //builds the static UI for the menu screen
  //StatelessWidget is used because this screen does not manage or mutate any internal state
  //it simply provides navigation controls to other stateful feature screens
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar provides a consistent top navigation bar across the application
      //displaying the application name for branding and user orientation
      appBar: AppBar(title: const Text("Insight")),

      //centres the main content of the menu screen both vertically and horizontally
      body: Center(
        child: Column(
          //vertically centres menu buttons for accessibility and ease of use, particularly important for visually impaired or assistive users
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              child: const Text("Chatbot"),
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
      ),
    );
  }
}
