//this pages opens the camera, lets the user take a picture, saves it, then sends it to the AI chatbot while speaking feedback

//imports the flutter camera plugin for accessing the device camera
import 'package:camera/camera.dart';

//imports core flutter matieral UI components (buttons, layouts, etc)
import 'package:flutter/material.dart';

//imports the gallery plugin to save images to the device gallery
import 'package:gal/gal.dart';

//imports the chatbot page so we can navigate to it after taking a picture
import 'chat_gemini.dart';

//imports text-to-speech so the app can talk to the user
import 'package:flutter_tts/flutter_tts.dart';

//this defines the camera page screen
//StatefulWidget means this page can change (camera loads, takes picture, etc)
//homepage widget represents the main screen of the application
// responsible for:
// - initialising the device camera
// - managing camera lifecycle across app changes
// - capturing and saving images locally
// - triggering navigation to the AI analysis screen
class CameraPage extends StatefulWidget {
  const CameraPage({super.key}); //constructor

  //creates the state (logic + UI control) for this page
  //StatefulWidget is required because camera initialisation, preview rendering and lifecycle changes all require dynamic UI updates
  @override
  State<CameraPage> createState() => _CameraPageState();
}

//this class contains ALL logic for the camera page
//WidgetsBindingObserver lets use detect app lifecycle (app/resume)
//state the class that manages camera resources, responding to app lifecycle events and rebuilding the UI
class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> cameras =
      []; //stores all available cameras on the device (Front + back)
  CameraController? //manages the selected camera stream (preview + taking pictures)
  cameraController; //controls the selected camera and manages camera operations

  //text-to-speech
  //creates a text-to-speech object so the app can speak
  final FlutterTts flutterTts = FlutterTts();

  //function to speak any text out loud
  Future<void> speak(String text) async {
    await flutterTts.stop(); //stops any current speech
    await flutterTts.speak(text); //speaks the new text
  }

  //runs when the page is first opened
  //called once when the widget is first created
  //this is the appropriate place to initialise long-lived resources such as the camera controller
  @override
  void initState() {
    super.initState();
    //tells fluter we want to listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // makes speech smoother (important) - waits until finished before next speech
    flutterTts.awaitSpeakCompletion(true);
    //slows down speech so it is easier to understand
    flutterTts.setSpeechRate(0.45);

    _setupCameraController(); //initialises the camera when the app starts - stes up camera
  }

  //runs when leaving the page (important for cleanup)
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); //stop listening to lifecycle
    cameraController?.dispose(); //release camera hardware
    flutterTts.stop(); //stop any speaking
    super.dispose();
  }

  //handles app lifecycle changes/ listens for app state changes (e.g. app paused or resumed, background and foreground)
  //this is critical for releasing hardware resources correctly and preventing camera lock or crashes, when the app is paused
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //if the camera controller is not ready, do nothing
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return;
    }
    //releases camera resources when the app becomes inactive
    //when the app becomes inactive (e.g. user switches apps)
    //the camera is explicitly disposed to free hardware resources
    //this prevents memory leaks and camera access conflicts
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
      //if app comes back then reopen camera
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController(); //reinitialises the camera when the app is resumed to restore functionality
    }
  }

  //sets up and initialises and configures the camera (very important function)
  Future<void> _setupCameraController() async {
    //gets list of all camera on the device
    List<CameraDescription> _cameras = await availableCameras();
    //proceeds only if at least one camera is available
    if (_cameras.isNotEmpty) {
      //update UI with camera info
      setState(() {
        //stores the list of cameras
        cameras = _cameras;
        //initialises the camera controller using the back camera (better quality)
        //rear camera is preferred for higher image quality in assistive and computer vision contexts
        cameraController = CameraController(
          _cameras.last,
          ResolutionPreset.high, //high quality images
        );
      });
      //initialises the camera asynchronously (happens in the background)
      cameraController
          ?.initialize()
          .then((_) {
            //if widget is gone, stop (prevents crashes)
            //prevents state update if the widget has been removed, avoiding crashes caused by asynchronous camera initialisation
            //this avoid common flutter lifecycle crashes
            if (!mounted) return;
            //refreshes the UI once the camera is ready
            setState(() {});
          })
          .catchError((e) {
            //print error if camera fails
            debugPrint(e.toString());
          });
    }
  }

  //builds the main screen UI scaffold for the camera screen
  //this provides consistent navigation structure and layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //app bar with a title
      appBar: AppBar(
        title: const Text("Detect Picture"),
        //back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          //when pressed, speak + go back
          onPressed: () async {
            await speak("Navigating back to home page");
            Navigator.pop(context);
          },
        ),
      ),
      //builds the camera interface (main camera UI)
      body: _buildUI(),
    );
  }

  //builds the camera preview and capture button for the user interface (builds camera preview + button)
  Widget _buildUI() {
    //shows a loading indicator while the camera is initialising (if not ready)
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      //ensures UI avoids system areas such as the notch (buttons, text and camera preview do not overlap with hardware or system elements)
      child: SizedBox.expand(
        //expands content to fill the screen
        child: Column(
          //spaces elements evenly on the screen
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //centres elements horizontally
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //displays the live camera feed to the user
            SizedBox(
              //sets camera preview height dynamically
              height: MediaQuery.sizeOf(context).height - 250,
              //uses full screen width
              width: MediaQuery.sizeOf(context).width,
              //shows the live camera stream
              child: CameraPreview(cameraController!),
            ),

            //camera capture button
            IconButton(
              //sets the icon size - large icon size improves accessibility and usability
              iconSize: 100,
              //displays a red camera icon which provides clear visual utility for the capture action
              icon: const Icon(Icons.camera, color: Colors.red),
              //triggered when the user presses the camera button (when pressed, take picture)
              onPressed: () async {
                try {
                  //takes a high resolution image using the camera
                  XFile picture = await cameraController!.takePicture();

                  //saves the captures image to the device gallery
                  //this supports secure local storage, auditability and optional later user review
                  await Gal.putImage(picture.path);

                  //speak before navigation
                  await speak("Sending picture to ai assistant");

                  //navigates to the gemini chat screen, passing the image path as a parameter
                  //this enables automated multimodal AI analysis on screen load in the next widget
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatGeminiPage(
                        initialImagePath: picture.path,
                        fromCamera: true,
                      ),
                    ),
                  );
                } catch (e) {
                  //print error if something fails
                  debugPrint("Camera error: $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
