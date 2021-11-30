import 'dart:io';

import 'package:camera/camera.dart';
import 'package:carfare/screens/guard_home.dart';
import 'package:carfare/screens/home.dart';
import 'package:carfare/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../genericWidgets.dart';
import '../main.dart';

enum ScreenMode { gallery }

class CameraView extends StatefulWidget {
  CameraView(
      {Key key,
      @required this.title,
      @required this.customPaint,
      @required this.ic,
      this.onImage,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint customPaint;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;
  final IconButton ic;

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final _auth = FirebaseAuth.instance; //auth data
  final _firestore = FirebaseFirestore.instance; //send and get data
  ScreenMode _mode = ScreenMode.gallery;
  CameraController _controller;
  File _image;
  ImagePicker _imagePicker;
  int _cameraIndex = 0;
  //temp
  String numpy;

  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == widget.initialDirection) {
        _cameraIndex = i;
      }
    }
    //_startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  void custom(){
    // showAnimatedDialog(
    //   context: context,
    //   barrierDismissible: true,
    //   builder: (BuildContext context) {
    //     return ClassicGeneralDialogWidget(
    //       titleText: 'Title',
    //       contentText: 'content',
    //       onPositiveClick: () {
    //         Navigator.of(context).pop();
    //       },
    //       onNegativeClick: () {
    //         Navigator.of(context).pop();
    //       },
    //     );
    //   },
    //   animationType: DialogTransitionType.size,
    //   curve: Curves.fastOutSlowIn,
    //   duration: Duration(seconds: 1),
    // );
  }
  void _openCustomDialog() {
    showGeneralDialog(
        barrierColor: Color(0xFF141313).withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
              opacity: a1.value,
              child: Center(
                child: AlertDialog(
                  shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  title: Image.asset('images/tick.gif',height: 125.0, width: 125.0,),
                  content: Text('Verified'),
                ),
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 100),
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
          ),
        ],
        leading: widget.ic,
      ),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _floatingActionButton() {
    if (_mode == ScreenMode.gallery) return null;
    if (cameras.length == 1) return null;
    return Container(
        height: 70.0,
        width: 70.0,
        child: FloatingActionButton(
          child: Icon(
            Platform.isIOS
                ? Icons.flip_camera_ios_outlined
                : Icons.flip_camera_android_outlined,
            size: 40,
          ),
          onPressed: _switchLiveCamera,
        ));
  }

  Widget _body() {
    Widget body;
    body = _galleryBody();
    return body;
  }

  Widget _galleryBody() {
    return ListView(shrinkWrap: true, children: [
      _image != null
          ? Container(
              height: 400,
              width: 400,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(_image),
                  if (widget.customPaint != null) widget.customPaint,
                ],
              ),
            )
          : Icon(
              Icons.image,
              size: 200,
            ),
      SizedBox(
        height: 48.0,
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('From Gallery'),
          onPressed: () => _getImage(ImageSource.gallery),
        ),
      ),
      SizedBox(
        height: 48.0,
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('Take a picture'),
          onPressed: () => _getImage(ImageSource.camera),
        ),
      ),
      SizedBox(
        height: 38.0,
      ),
      Center(
          child: Text(
        'Visual NOT working? Check Manually\nExample: ABC-00-1234',
        style: TextStyle(color: Colors.white),
      )),
      SizedBox(
        height: 38.0,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InputField(
          onChange: (value) {
            numpy = value;
          },
          bcolor: Colors.blue,
          text: 'Enter Number Plate',
          type: TextInputType.emailAddress,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ButtonBuilder(
          onPress: () async {
            numpy.toUpperCase();
            print(numpy);
            TextDetectorViewState().getUserInfo(numpy.toUpperCase());
            //checkSyntax();
            _openCustomDialog();
          },
          color: Colors.green,
          text: 'CHECK',
        ),
      ),
      // Padding(
      //   padding: EdgeInsets.symmetric(horizontal: 16),
      //   child: ElevatedButton(
      //     child: Text('EXIT TESTING SCREEN'),
      //     onPressed: () async {
      //       // SharedPreferences pref =
      //       //     await SharedPreferences.getInstance();
      //       // pref.remove('email');
      //       showToast(
      //           'LOGGED OUT', Colors.lightBlueAccent, Icons.check);
      //       _auth.signOut();
      //       Navigator.popAndPushNamed(context, LoginScreen.id);
      //     },
      //   ),
      // ),
    ]);
  }

  Future _getImage(ImageSource source) async {
    final pickedFile = await _imagePicker?.getImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    } else {
      print('No image selected.');
    }
    setState(() {});
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    _controller?.initialize()?.then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    if (_cameraIndex == 0)
      _cameraIndex = 1;
    else
      _cameraIndex = 0;
    await _stopLiveFeed();
    await _startLiveFeed();
  }

  Future _processPickedFile(PickedFile pickedFile) async {
    setState(() {
      _image = File(pickedFile.path);
    });
    final inputImage = InputImage.fromFilePath(pickedFile.path);
    widget.onImage(inputImage);
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
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

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage);
  }
}
