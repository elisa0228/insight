import 'package:camera/camera.dart'; //imports the flutter camera plugin for accessing the device camera
import 'package:flutter/material.dart'; //imports core flutter matieral UI components
import 'package:gal/gal.dart'; //imports the gallery plugin to save images to the device gallery

//homepage widget represents the main screen of the application
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  //creates the mutable state for this widget
  @override
  State<CameraPage> createState() => _CameraPageState();
}

//state the class that manages camera lifecycle (started, paused, resumed) and UI updates
class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> cameras =
      []; //stores all available cameras on the device
  CameraController?
  cameraController; //controls the selected camera and manages camera operations

  //handles app lifecycle changes (e.g. app paused or resumed)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    //if the camera controller is not ready, exit early
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return;
    }
    //releases camera resources when the app becomes inactive
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    }
    //reinitialises the camera when the app is resumed
    else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  //called once when the widget is first created
  @override
  void initState() {
    super.initState();
    _setupCameraController(); //initialises the camera when the app starts
  }

  //builds the main UI scaffold of the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //app bar with a title
      appBar: AppBar(title: const Text("Detect Picture")),
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
            //displays the live camera feed
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
              //triggered when the user presses the camera button
              onPressed: () async {
                //takes a photo using the camera
                XFile picture = await cameraController!.takePicture();
                //saves the captures image to the device gallery
                Gal.putImage(picture.path);
              },
              //sets the icon size
              iconSize: 100,
              //displays a red camera icon
              icon: const Icon(Icons.camera, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  //sets up and initialises the camera controller
  Future<void> _setupCameraController() async {
    //retrieves all camera available on the device
    List<CameraDescription> _cameras = await availableCameras();
    //proceeds only if at least one camera is available
    if (_cameras.isNotEmpty) {
      setState(() {
        //stores the list of cameras
        cameras = _cameras;
        //initialises the camera controller using the back camera
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
            if (!mounted) {
              return;
            }
            //refreshes the UI once the camera is ready
            setState(() {});
          })
          //handles camera initialisation errors
          .catchError((Object e) {
            print(e);
          });
    }
  }
}
