import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(
    MyHomePage(),
  );
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage _cameraImage;
  CameraController controller;
  bool isprocessing = false;
  String result = '';
  ImageLabeler imageLabeler;

  @override
  void initState() {
    super.initState();
    imageLabeler = GoogleMlKit.vision.imageLabeler();
  }

  initializeCamera() async {
    controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
    );
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isprocessing)
              {
                isprocessing = true,
                _cameraImage = image,
                doImageLabeling(),
              }
          });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  doImageLabeling() async {
    result = '';
    InputImage inputImage = getInputImage();
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    for (ImageLabel label in labels) {
      final String text = label.label;
      final double confidence = label.confidence * 100;
      result += text + "   " + confidence.toStringAsFixed(2) + '%' + '\n';
    }
    setState(() {
      isprocessing = false;
    });
  }

  InputImage getInputImage() {
    final WriteBuffer buffer = WriteBuffer();
    for (var plane in _cameraImage.planes) {
      buffer.putUint8List(
        plane.bytes,
      );
    }
    final bytes = buffer.done().buffer.asUint8List();
    final Size imageSize = Size(
      _cameraImage.width.toDouble(),
      _cameraImage.height.toDouble(),
    );
    InputImageRotation imageRotation;
    imageRotation = InputImageRotationMethods.fromRawValue(
          cameras[0].sensorOrientation,
        ) ??
        InputImageRotation.Rotation_0deg;
    InputImageFormat inputImageFormat;
    inputImageFormat = InputImageFormatMethods.fromRawValue(
          _cameraImage.format.raw,
        ) ??
        InputImageFormat.NV21;
    final planeData = _cameraImage.planes.map(
      (plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();
    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      inputImageData: inputImageData,
    );
    return inputImage;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'images/image.jpg',
              ),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(
                        top: 100,
                      ),
                      height: 300,
                      width: 320,
                      child: Image.asset(
                        'images/LCD.jpg',
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      child: Container(
                        margin: EdgeInsets.only(
                          top: 130,
                        ),
                        height: 200,
                        width: 310,
                        child: _cameraImage == null
                            ? Container(
                                width: 150,
                                height: 200,
                                child: Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                ),
                              )
                            : AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: CameraPreview(
                                  controller,
                                ),
                              ),
                      ),
                      onPressed: () {
                        initializeCamera();
                      },
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  child: SingleChildScrollView(
                    child: Text(
                      '$result',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
