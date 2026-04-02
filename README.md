# InSight
### An intelligent visual companion for the visually impaired

Insight is a cross-platform Flutter mobile application that enables users to capture or upload images and receive real-time, spoken and visual, detailed, AI-generated descriptions using a multimodal large language model (Google Gemini). The application is designed to support accessibility, assistive technology use cases and general-purpose visual interpretation by combining real-time camera input with cloud-based AI image understanding.

The system integrates:
* Native mobile camera hardware
* Secure on-device image storage
* Cloud-based AI vision
* Voice interaction (text-to-speech + speech-to-text)

The architecture emphasises modularity, privacy-aware data handling and responsive UI design.

Insight creates a hands-free, accessible experience for understanding the environment.


### Key Features:
* Real-time camera capture using native device hardware
* Secure local image storage via device gallery
* Multimodal AI image understanding (image + text via Gemini)
* Streaming AI chat interface (real time responses)
* Text-to-Speech (TTS) for spoken AI responses
* Speech-to-Text (STT) for voice-based interaction
* Voice-guided navigation feedback (e.g. "Opening chatbot page")
* Cross-platform support for Android and iOS
* Modular architecture (navigation between camera, menu and chat screens)
* Designed with accessibility and assistive use cases in mind (large buttons, voice guidance)

### Tools and Technologies Used:
* Flutter (Dart): Cross-platform mobile development
* Google Gemini API: Multimodal AI (image + text understanding)
* flutter_gemini: Flutter SDK for Gemini integration
* camera: Native camera access for Android and iOS
* gal: Secure image saving to device gallery
* dash_chat_2: Chat UI framework
* image_picker: Gallery image selection
* flutter_tts: Text-to-Speech output
* speech-to-text: Voice input recognition
* Android Studio/Xcode: Platform-specific build and deployment tools


### Project Architecture 

**main.dart**
* Application entry point and app-level configuration
* Initialises Gemini API
* Loads the main navigation system

**new_menu_page.dart**\
Acts as the main navigation hub of the application.
Provides two large, accessible interaction areas:
* Top half → Camera (scan environment)
* Bottom half → Chatbot (voice assistant)
* Includes spoken onboarding instructions:
      "tap the top card to scan your environment..."

This ensures a clean separation between UI navigation and feature-specific screens.

**camera_picture.dart**\
Handles all camera-related functionality:
* Camera initialisation and lifecycle management
* Live camera preview
* Image capture and secure local storage
* Voice feedback (e.g. "sending picture to chatbot")
* Navigation to AI analysis screen with image path

Implements lifecycle observers to prevent crashes and release camera when app is backgrounded.

**chat_gemini.dart**\
Implements the multimodal AI interaction pipeline:
* Accepts text, voice and images
* Converts images to byte data for Gemini API
* Streams AI-generated responses in real time
* Displays responses in chat user interface
* Speaks responses aloud (TTS)
* Supports continuous voice interaction

This file contains advanced streaming logic to merge partial LLM outputs into logical chat messages.

**constant.dart**
* A constant value used to authentical my app with the gemini AI service
* Stores the gemini API key
* The keys is used to connect the app to google's AI (gemini)

**Image-to-AI Pipeline**
1. User taps 'Scan Enviroment'
2. Camera opens and captures image
3. User captures image via *CameraPage*
4. Image is saved locally to device gallery
5. Image is passed to 'ChatGeminiPage'
6. Image path is passed using *Navigator.push*
7. Image is converted to byte data
8. Sent to Gemini API
9. Gemini streams descriptive text responses
10. Response is:
    * displayed in chat
    * spoken aloud

### Setup and Installation
**Prerequisites** 
* Flutter SDK installed
* Android Studio and/or Xcode installed
* Physcial device or emulator
* Gemini API key

### Platform-Specific Requirements
*Android*
* Camera permission in *AndroidManifest.xml*
* Internet permission for Gemini API access

*iOS*
* Camera usage description in *Info.plist*
* Microphone usage description
* Photo library usage description
* Proper Xcode device pairing for physical devices 

### Challenges and Limitations
**Challenges**
* Managing camera lifecycle across app background/foregorund transitions
* Handling streamed AI responses correctly and merging partial text segments
* Navigation timing between camera capture and automated AI requests
* Intermittent iOS VM service connection issues during physcial device deployment
* Voice recognition reliability across devices
* Preventing duplicate speech/ feedback loops
These were addressed through lifecycle observers, timers and restart logic, defensive null checks, UI state validation and imrpoved stream handling logic (controlled speech states).

**Limitations**
* Requires active internet connection for AI processing
* AI responses depend on external LLM availability and rate limits (request prompt limit)
* No offline AI processing
* Current implementation does not include persistent chat history (session-based only)

### Ethical and Privacy Considerations
* Images are stored locally on-device only
* No external database storage of images
* AI requests are sent securely to Gemini
* Designed to minimise unnecessary data retention
* Supports evaluation of model bias under varied lighting and environments

### Future Features
* Offline capabilities
* Persistent chat history
* Improved voice command reliability
* Fully voice command to navigate to different pages
* Object detection + distance estimation accuracy produced
* Custom user accessibility settings

### Credits
* Google Gemini API
* Flutter & Dart ecosystem
* dash_chat_2 package contributors
* Flutter camera plugin maintainers
