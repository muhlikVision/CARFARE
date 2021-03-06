import 'dart:io';

import 'package:camera/camera.dart';
import 'package:carfare/screens/guard_home.dart';
import 'package:carfare/screens/home.dart';
import 'package:carfare/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
  final msgTextCont = TextEditingController();
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


  Future<void> showMyWrongDialog(String text, String anim) async {
    return showDialog(
      context: context,
      //barrierColor:  Colors.deepOrange.withOpacity(0.5),// user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0)),
          title: Image.asset('images/$anim.gif', height: 100.0, width: 100.0,),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Center(child: Text('$text')),

              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {

                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      },
    );
  }

  updateTrafficMonitor(floor) async{
    print('in traffic updater');
    try{
      for (int i = 0; i < trafficMonitorDocNames.length; i++) {
        var docSnapshot = await _firestore
            .collection('TrafficMonitor')
            .doc(trafficMonitorDocNames[i])
            .get();
        if (docSnapshot.exists) {
          Map<String, dynamic> data = docSnapshot.data();

          final n = data['number_plate'];
          final t = data['time_date'];
          final status = data['status'];
          final flor = data['floor'];
          final type = data['type'];

          if(n == tempGetNumberPlate && status == true){
            try{
              var docSnapshot =
              await _firestore.collection('TrafficMonitor').doc(trafficMonitorDocNames[i]).get();
              if (docSnapshot.exists) {
                //Map<String, dynamic> data = docSnapshot.data();


                _firestore.collection('TrafficMonitor').doc() // <-- Document ID
                    .set({
                  'number_plate' : n,
                  'time_date' : TextDetectorViewState().getTime(),
                  'status': false,
                  'floor' : flor,
                  'type': vehicle_status,
                });
                _firestore.collection('TrafficMonitor').doc(trafficMonitorDocNames[i]) // <-- Document ID
                    .set({
                  'number_plate' : n,
                  'time_date' : t,
                  'status': false,
                  'floor' : flor,
                  'type': type,
                });

                try {
                  var docSnapshot =
                  await _firestore.collection('Parking Area').doc(flor).get();
                  if (docSnapshot.exists) {
                    Map<String, dynamic> data = docSnapshot.data();

                    final at = data['AreaTitle'];
                    final rc = data['Reserved'];
                    final c = data['count'];

                    try {
                      var docSnapshot = await _firestore.collection('Parking Area').get();
                      if (docSnapshot != null) {
                        //Map<String, dynamic> data = docSnapshot.data();
                        // setState(() {
                        //   currentState = WAIT.RESERVATIONS;
                        // });

                        _firestore.collection('Parking Area').doc(
                            flor) // <-- Document ID
                            .set({
                          'AreaTitle': at,
                          'Reserved': rc,
                          'count': c - 1,
                        });
                        showToast(
                            'Overall count updated\nFLOOR | $flor', Colors.greenAccent, Icons.check);
                      } else {
                        showToast('error', Colors.redAccent, Icons.clear);
                        // setState(() {
                        //   currentState = WAIT.RESERVATIONS;
                        // });
                        //showMyDialog('NO RECORD FOUND','cross');
                      }
                    } catch (e) {
                      showToast('$e', Colors.redAccent, Icons.clear);
                    }
                  } else {
                    showToast('no floor record found', Colors.redAccent, Icons.clear);
                  }
                } catch (e) {
                  showToast('$e', Colors.redAccent, Icons.clear);
                }

                //showMyDialog('$carName has been Verified','tick');
                showToast('updated', Colors.greenAccent, Icons.check);

              } else {
                showToast('updation error', Colors.redAccent, Icons.clear);

                //showMyDialog('NO RECORD FOUND','cross');
              }
            }
            catch(e){
              showToast('doc id error', Colors.redAccent, Icons.clear);
            }
          }
          else
          {
            print('fucked up');
          }
        }
      }
    }
    catch(e){
      showToast('doc id error', Colors.redAccent, Icons.clear);
    }

  }

  updateParkingCountAuto(floor, modeOfEntry) async {
    if(modeOfEntry == 'entry') {
      try {
        var docSnapshot =
        await _firestore.collection('Parking Area').doc(floor).get();
        if (docSnapshot.exists) {
          Map<String, dynamic> data = docSnapshot.data();

          final at = data['AreaTitle'];
          final rc = data['Reserved'];
          final c = data['count'];

          try {
            var docSnapshot = await _firestore.collection('Parking Area').get();
            if (docSnapshot != null) {
              //Map<String, dynamic> data = docSnapshot.data();
              // setState(() {
              //   currentState = WAIT.RESERVATIONS;
              // });

              _firestore.collection('Parking Area').doc(
                  floor) // <-- Document ID
                  .set({
                'AreaTitle': at,
                'Reserved': rc,
                'count': c + 1,
              });
              showToast(
                  'Overall count updated', Colors.greenAccent, Icons.check);
            } else {
              showToast('error', Colors.redAccent, Icons.clear);
              // setState(() {
              //   currentState = WAIT.RESERVATIONS;
              // });
              //showMyDialog('NO RECORD FOUND','cross');
            }
          } catch (e) {
            showToast('$e', Colors.redAccent, Icons.clear);
          }
        } else {
          showToast('no floor record found', Colors.redAccent, Icons.clear);
        }
      } catch (e) {
        showToast('$e', Colors.redAccent, Icons.clear);
      }
    }
    else if (modeOfEntry == 'exit'){
      updateTrafficMonitor(floor);
    }
    else
      showToast('error in mode of entry', Colors.redAccent, Icons.clear);
  }

  getUserInfo(String sendToFb) async {
    try {
      var docSnapshot =
      await _firestore.collection('Vehicles').doc(sendToFb).get();
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data();

        final carName = data['Name'];
        // setState(() {
        //   currentState = WAIT.DATA_FETCHED;
        // });

        if(vehicle_status == 'entry') {
          _firestore.collection('TrafficMonitor').doc()
              .set({
            'number_plate': sendToFb,
            'type': vehicle_status,
            'time_date': TextDetectorViewState().getTime(),
            'floor': finalFloor,
            'status': true,
          });
        }

        setState(() {
          tempGetNumberPlate = sendToFb;
        });

        if(finalFloor == null){finalFloor = '';}
        updateParkingCountAuto(finalFloor.toUpperCase(), vehicle_status);

        showMyWrongDialog('$carName has been Verified\n\n TYPE: $vehicle_status', 'tick');
        //showToast('$carName has been Verified', Colors.greenAccent, Icons.check);
      } else {
        //showToast('No record found', Colors.redAccent, Icons.clear);

        showMyWrongDialog('NO RECORD FOUND', 'cross');
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }


  bool chkNumpySyntax(String n){

    bool flag = false;
    if (n[2] == '-' || n[3] == '-'){
      flag = true;
      if(n[3] =='0' || n[3] =='1' ||n[3] =='2'){
        flag = true;
        if(n[3+1] == '0' ||n[3+1] == '1' ||n[3+1] == '2' ||n[3+1] == '3' ||n[3+1] == '4' ||n[3+1] == '5' ||n[3+1] == '6' ||n[3+1] == '7' ||n[3+1] == '8' ||n[3+1] == '9'){
          flag = true;
          if(n[3+2] != '-'){flag = false;}
        }
        else{flag = false;}
      }
      else if(n[4] =='0' || n[4] =='1' ||n[4] =='2'){
        //print(1);
        flag = true;
        if(n[3+1] == '0' ||n[3+1] == '1' ||n[4+1] == '2' ||n[4+1] == '3' ||n[4+1] == '4' ||n[4+1] == '5' ||n[4+1] == '6' ||n[4+1] == '7' ||n[4+1] == '8' ||n[4+1] == '9'){
          flag = true;
          if(n[4+2] != '-'){flag = false;}
          //print(2);
        }
        else{flag = false;}
      }
      else
      {
        // print(3);
        flag = false;
      }
    }
    else{
      //print(4);
      flag = false;
    }

    int s = n.length-1;

    return flag;

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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ButtonBuilder(
          onPress: () {
            _getImage(ImageSource.gallery);
          },
          color: Colors.blue,
          text: 'From Gallery',
        ),
      ),
      // Padding(
      //   padding: EdgeInsets.symmetric(horizontal: 16),
      //   child: ElevatedButton(
      //     child: Text('From Gallery'),
      //     onPressed: () => _getImage(ImageSource.gallery),
      //   ),
      // ),
      // SizedBox(
      //   height: 48.0,
      // ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ButtonBuilder(
          onPress: () {
            _getImage(ImageSource.camera);
          },
          color: Colors.blue,
          text: 'Take a picture',
        ),
      ),
      // Padding(
      //   padding: EdgeInsets.symmetric(horizontal: 16),
      //   child: ElevatedButton(
      //     child: Text('Take a picture'),
      //     onPressed: () => _getImage(ImageSource.camera),
      //   ),
      // ),
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
          tec: msgTextCont,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ButtonBuilder(
          onPress: () async {


            print(numpy);
            if(numpy != '' && numpy != null) {
              if (chkNumpySyntax(numpy) == true) {
                getUserInfo(numpy.toUpperCase());
                //checkSyntax();
                //_showMyDialog('VERIFIED');
              }
            }
            else
              {
                showToast('Invalid Number Plate Syntax', Colors.redAccent, Icons.clear);
              }
            msgTextCont.clear();
            numpy = null;
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
