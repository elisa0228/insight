import 'package:camera/camera.dart'; //imports the flutter camera plugin for accessing the device camera
import 'package:flutter/material.dart'; //imports core flutter matieral UI components
import 'package:gal/gal.dart'; //imports the gallery plugin to save images to the device gallery
import 'chat_gemini.dart'; //imports the llm function
import 'package:flutter_tts/flutter_tts.dart'; //convert text output into spoken audio using the device's built-in text-to-speech engine

//homepage widget represents the main screen of the application
// responsible for:
// - initialising the device camera
// - managing camera lifecycle across app changes
// - capturing and saving images locally
// - triggering navigation to the AI analysis screen
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  //creates the mutable state object for this widget
  //StatefulWidget is required because camera initialisation, preview rendering and lifecycle changes all require dynamic UI updates
  @override
  State<CameraPage> createState() => _CameraPageState();
}

//state the class that manages camera resources, responding to app lifecycle events and rebuilding the UI
class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> cameras =
      []; //stores all available cameras on the device - rear camera, front camera
  CameraController? //manages the selected camera stream, handles preview rendering and executed image capture
  cameraController; //controls the selected camera and manages camera operations

  // 🔊 TEXT TO SPEECH
  final FlutterTts flutterTts = FlutterTts();

  Future<void> speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  //called once when the widget is first created
  //this is the appropriate place to initialise long-lived resources such as the camera controller
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // smoother speech (important)
    flutterTts.awaitSpeakCompletion(true);
    flutterTts.setSpeechRate(0.45);

    _setupCameraController(); //initialises the camera when the app starts
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  //handles app lifecycle changes (e.g. app paused or resumed, background and foreground)
  //this is critical for releasing hardware resources correctly and preventing camera lock or crashes, when the app is paused
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //if the camera controller is not ready, exit early (not initialised, there is no reasource to manage)
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
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController(); //reinitialises the camera when the app is resumed to restore functionality
    }
  }

  //sets up and initialises and configures the camera controller
  Future<void> _setupCameraController() async {
    //retrieves all camera available on the device
    List<CameraDescription> _cameras = await availableCameras();
    //proceeds only if at least one camera is available
    if (_cameras.isNotEmpty) {
      setState(() {
        //stores the list of cameras
        cameras = _cameras;
        //initialises the camera controller using the back camera
        //rear camera is preferred for higher image quality in assistive and computer vision contexts
        cameraController = CameraController(
          _cameras.last,
          ResolutionPreset.high, //high resolution for clearer images
        );
      });
      //initialises the camera asynchronously (happens in the background)
      cameraController
          ?.initialize()
          .then((_) {
            //prevents state update if the widget has been removed, avoiding crashes caused by asynchronous camera initialisation
            //this avoid common flutter lifecycle crashes
            if (!mounted) return;
            //refreshes the UI once the camera is ready
            setState(() {});
          })
          .catchError((e) {
            //handles (logs) camera initialisation errors for debugging
            debugPrint(e.toString());
          });
    }
  }

  //builds the main UI scaffold for the camera screen
  //this provides consistent navigation structure and layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //app bar with a title
      appBar: AppBar(
        title: const Text("Detect Picture"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await speak("Navigating back to home page");
            Navigator.pop(context);
          },
        ),
      ),
      //builds the camera interface
      body: _buildUI(),
    );
  }

  //builds the camera preview and capture button for the user interface
  Widget _buildUI() {
    //shows a loading indicator while the camera is initialising
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
              //triggered when the user presses the camera button
              onPressed: () async {
                try {
                  //takes a high resolution image using the camera
                  XFile picture = await cameraController!.takePicture();

                  //saves the captures image to the device gallery
                  //this supports secure local storage, auditability and optional later user review
                  await Gal.putImage(picture.path);

                  //speak before navigation
                  await speak("Sending picture to chatbot");

                  //navigates to the gemini chat screen, passing the image path as a parameter
                  //this enables automated multimodal AI analysis on screen load in the next widget
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatGeminiPage(initialImagePath: picture.path),
                    ),
                  );
                } catch (e) {
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
