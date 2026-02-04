# InSight
### An intelligent visual companion for the visually impaired

Insight is a cross-platform Flutter mobile application that enables users to capture or upload images and receive detailed, AI-generated descriptions using a multimodal large language model (Google Gemini). The application is designed to support accessibility, assistive technology use cases and general-purpose visual interpretation by combining real-time camera input with cloud-based AI image understanding.

The system integrates native mobile camera hardware, secure on-device image storage and a streamed AI chat interface to provide near real-time, context-aware descriptions of visual scenes. The architecture emphasises modularity, privacy-aware data handling and responsive UI design.


### Key Features:
* Real-time camera capture using native device hardware
* Secure local image storage via device gallery
* Multimodal AI image understanding using Gemini
* Streaming AI chat interface with partial response updates
* Cross-platform support for Android and iOS
* Modular navigation between camera, menu and chat screens
* Designed with accessibility and assistive use cases in mind

### Tools and Technologies Used:
* Flutter (Dart): Cross-platform mobile development
* Google Gemini API: Multimodal large language model for image + text understanding
* flutter_gemini: Flutter SDK for Gemini integration
* camera: Native camera access for Android and iOS
* gal: Secure image saving to device gallery
* dash_chat_2: Chat UI framework
* image_picker: Gallery image selection
* Android Studio/Xcode: Platform-specific build and deployment tools


### Project Architecture 

**main.dart**\
Application entry point and app-level configuration.

**menu_page.dart**\
Provides the main navigation hub of the application.
Allows users to choose between:
* Taking a new picture using the camera
* Opening the chatbot interface directly

This ensures a clean separation between UI navigation and feature-specific screens.

**camera_picture.dart**\
Manages all camera-related functionality:
* Camera initialisation and lifecycle management
* Live camera preview
* Image capture and secure local storage
* Navigation to AI analysis screen with image path

Implements lifecycle observers to correctly release and reinitialise camera hardware.

**chat_gemini.dart**\
Implements the multimodal AI interaction pipeline:
* Accepts image paths passed from the camera screen
* Converts images to byte arrays for Gemini API
* Streams AI-generated responses in real time
* Updates chat UI incrementally as partial responses arrive
* Supports both camera images and gallery-selected images

This file contains advanced streaming logic to merge partial LLM outputs into logical chat messages.

**Image-to-AI Pipeline**
1. User captures image via *CameraPage*
2. Image is saved locally to device gallery
3. Image path is passed using *Navigator.push*
4. *ChatGeminiPage* auto-sends image on screen load
5. Image bytes are sent to Gemini API
6. Gemini streams descriptive text responses
7. UI updates incrementally with AI output

### Setup and Installation
**Prerequisites** 
* Flutter SDK installed
* Android Studio and/or Scode installed
* Physcial device or emulator
* Gemini API key

### Platform-Specific Requirements
*Android*
* Camera permission in *AndroidManifest.xml*
* Internet permission for Gemini API access

*iOS*
* Camera usage description in *Info.plist*
* Photo library usage description
* Proper Xcode device pairing for physical devices 

### Challenges and Limitations
**Challenges**
* Managing camera lifecycle across app background/foregorund transitions
* Handling streamed LLM responses and merging partial text segments
* Navigation timing between camera capture and automated AI requests
* Intermittent iOS VM service connection issues during physcial device deployment
* Inconsistent null or partial text in Gemini streaming responses
These were addressed through lifecycle observers, defensive null checks, UI state validation and imrpvoed stream handling logic.

**Limitations**
* Requires active internet connection for AI processing
* AI responses depend on external LLM availability and rate limits (request prompt limit)
* No offline image understanding
* No on-device machine learning inference (cloud-based only)
* Current implementation does not include persistent chat history

### Ethical and Privacy Considerations
* Images are stores locally on-device only
* No external database storage of images
* AI requests are sent securely to Gemini
* Designed to minimise unnecessary data retention
* Supports evaluation of model bias under varied lighting and environments

### Credits
* Google Gemini API
* Flutter & Dart ecosystem
* dash_chat_2 package contributors
* Flutter camera plugin maintainers
