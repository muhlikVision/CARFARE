import 'dart:math';

import 'package:carfare/VisionDetectorViews/camera_view.dart';
import 'package:carfare/VisionDetectorViews/painters/text_detector_painter.dart';
import 'package:carfare/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../genericWidgets.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';

String num = '';
int x = 0;
List<String> numberPlate = [];
String vehicle_status = 'entry';
List<String> parkingFloorNames = [''];

enum STATE {
  MAIN,
  SCAN,
  TOKEN,
  CURRENT_STATUS,
}

class GuardScreen extends StatefulWidget {
  static const String id = 'guard_screen';

  @override
  TextDetectorViewState createState() => TextDetectorViewState();
}

//TODO:...............................................
//TODO: ADD GUEST TOKEN AND Manual syntax checker AND Floor counter

class TextDetectorViewState extends State<GuardScreen> {
  final _auth = FirebaseAuth.instance; //auth data
  final _firestore = FirebaseFirestore.instance;
  TextDetector textDetector = GoogleMlKit.vision.textDetector();
  bool isBusy = false;
  CustomPaint customPaint;

  String sendToFb;
  List<CustomFloorTile> floorsBox = [];
  int floorCount;
  STATE currentState = STATE.MAIN;


  @override
  void dispose() async {
    super.dispose();
    await textDetector.close();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    fToast = FToast();
    fToast.init(context);
  }

  callBackState(c){
      setState(() {
        currentState = STATE.MAIN;
        floorsBox.clear();
      });
  }


  Future<void> showMyDialog(String text, String anim) async {
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



  getParkingCount() async {
    try {
      final QuerySnapshot result =
      await _firestore.collection('Parking Area').get();
      final List<DocumentSnapshot> documents = result.docs;

      if (documents != null) {
        //documents.forEach((data) => print(data.id));
        documents.forEach((data) {
          parkingFloorNames.add(data.id);
        });
        print(parkingFloorNames);
        parkingfloorsAdd();
        //parkingFloorNames.clear();
      }
      else {
        showToast('no data found', Colors.redAccent, Icons.clear);
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }
  parkingfloorsAdd() async {
    for (int i = 0; i < parkingFloorNames.length; i++) {
      var docSnapshot = await _firestore
          .collection('Parking Area')
          .doc(parkingFloorNames[i])
          .get();
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data();

        final c = data['count'];

        setState(() {
          floorCount = c;
        });
        final fBox = CustomFloorTile(
          floorName: parkingFloorNames[i], count: floorCount,callBackState: callBackState,);
        floorsBox.add(fBox);
      }
    }
    parkingFloorNames.clear();
    setState(() {
      currentState = STATE.CURRENT_STATUS;
    });

  }

    main(context) {
      return WillPopScope(
        onWillPop: () {
          return;
        },
        child: Scaffold(
            backgroundColor: Color(0xFF141313),
            appBar: AppBar(
              title: Text('GUARD PANEL'),
              elevation: 20,
              backgroundColor: color,
              automaticallyImplyLeading: false,
            ),
            resizeToAvoidBottomInset: true,
            body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () {
                            setState(() {
                              currentState = STATE.SCAN;
                              vehicle_status = 'entry';
                            });
                            showToast('$vehicle_status', Colors.blueAccent,
                                Icons.check);
                          }, color: Colors.green, text: 'ENTRY'),
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () {
                            setState(() {
                              currentState = STATE.SCAN;
                              vehicle_status = 'exit';
                            });
                            showToast('$vehicle_status', Colors.blueAccent,
                                Icons.check);
                          }, color: Colors.red, text: 'EXIT'),
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () async {
                            parkingFloorNames.clear(); 
                            getParkingCount();



                          }, color: Colors.blue, text: 'CHECK PARKING STATUS'),
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () {
                            setState(() {
                              currentState = STATE.TOKEN;
                            });
                          }, color: Colors.blue, text: 'REGISTER A GUEST'),
                      SizedBox(
                        height: 24.0,
                      ),
                    ]))),
      );
    }
    token(context) {
      return WillPopScope(
        onWillPop: () {
          return;
        },
        child: Scaffold(
            backgroundColor: Color(0xFF141313),
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    currentState = STATE.MAIN;
                  });
                },
              ),
              title: Text('REGISTER A GUEST TOKEN'),
              elevation: 20,
              backgroundColor: color,
              automaticallyImplyLeading: false,
            ),
            resizeToAvoidBottomInset: true,
            body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: 24.0,
                      ),
                      // Center(
                      //   child: Text(
                      //     'Please Enter Right Credentials in all fields',
                      //     style: TextStyle(color: Colors.white, fontSize: 18, fontStyle: FontStyle.normal),
                      //   ),
                      // ),
                      // SizedBox(
                      //   height: 24.0,
                      // ),
                      Center(
                        child: Text(
                          "Guest's Full Name: *",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      InputField(
                        onChange: (value) {

                        },
                        bcolor: Colors.blue,
                        text: 'Name here',
                        type: TextInputType.name,
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Center(
                        child: Text(
                          "Car's Number Plate with accurate Syntax: *",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      InputField(
                        onChange: (value) {

                        },
                        bcolor: Colors.blue,
                        text: 'ABC-XX-XXXX',
                        type: TextInputType.name,
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Center(
                        child: Text(
                          "Guest's CellPhone: *",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      InputField(
                        onChange: (value) {

                        },
                        bcolor: Colors.blue,
                        text: '+92-XXX-XXXXXXX',
                        type: TextInputType.phone,
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Center(
                        child: Text(
                          "Payment Amount (OPTIONAL)",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      InputField(
                        onChange: (value) {

                        },
                        bcolor: Colors.green,
                        text: '0.0',
                        type: TextInputType.number,
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Center(
                        child: Text(
                          "Purpose of visit: *",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      InputField(
                        onChange: (value) {

                        },
                        bcolor: Colors.blue,
                        text: 'faculty name',
                        type: TextInputType.text,
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () async {

                          }, color: Colors.green, text: 'SAVE INFO'),
                      SizedBox(
                        height: 24.0,
                      ),
                    ]))),
      );
    }
    scan(context) {
      return CameraView(
        title: 'SCAN NUMBER PLATE',
        customPaint: customPaint,
        onImage: (inputImage) async {
          await processImage(inputImage);
        },
        ic: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              currentState = STATE.MAIN;
            });
          },
        ),
      );
    }
    liveStatus(context) {
      return WillPopScope(
        onWillPop: () async {
          return;
        },
        child: Scaffold(
          backgroundColor: Color(0xFF141313),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                floorsBox.clear();
                setState(() {
                  currentState = STATE.MAIN;
                });
              },
            ),
            title: Text('Parking LIVE status'),
            elevation: 20,
            backgroundColor: color,
          ),
          body: ListView(
            shrinkWrap: true,
            children: floorsBox,
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      if (currentState == STATE.MAIN) {
        return main(context);
      } else if (currentState == STATE.SCAN) {
        return scan(context);
      } else if (currentState == STATE.TOKEN) {
        return token(context);
      } else {
        return liveStatus(context);
      }
    }

    String getTime() {
      String now = DateTime.now().toString();
      return now;
    }

    void disPlate(List<String> n) {
      //LEB 15,1234

      List<int> temp;
      try {
        for (int i = 0; i < n.length; i++) {
          for (int j = 0; j < n[i].length; j++) {
            //print(j);
            temp = n[i]
                .substring(j, j + 1)
                .codeUnits;
            //print('ASCII: $temp of ${n[i].substring(j, j + 1)}');
            if (n[i].substring(j, j + 1) == '-' ||
                n[i].substring(j, j + 1) == ' ' ||
                n[i].substring(j, j + 1) == 'L' ||
                temp[0] >= 48 && temp[0] <= 57) {
              if (n[i].substring(j, j + 1) == ' ') {
                List<String> tempS = n[i].split(' ');
                //print('tempS: $tempS');
                numberPlate.add(tempS[0]);
                numberPlate.add(tempS[1]);
                tempS.clear();
                j = n[i].length;
              }
              if (n[i].substring(j, j + 1) == 'L') {
                List<String> tempS = [];
                for (int l = 0; l < n[i].length; l++) {
                  if (n[i].substring(l, l + 1) == '-') {
                    tempS = n[i].split('-');
                    l = n[i].length;
                  } else if (n[i].substring(l, l + 1) == ' ') {
                    tempS = n[i].split(' ');
                    l = n[i].length;
                  }
                }
                //print('tempSL: $tempS');
                if (tempS.length == 2) {
                  numberPlate.add(tempS[0]);
                  numberPlate.add(tempS[1]);
                  tempS.clear();
                  j = n[i].length;
                } else {
                  numberPlate.add(n[i]);
                  j = n[i].length;
                }
              } else if (n[i].substring(j, j + 1) == '-') {
                List<String> tempS = n[i].split('-');
                //print('tempS-: $tempS');
                numberPlate.add(tempS[0]);
                numberPlate.add(tempS[1]);
                tempS.clear();
                j = n[i].length;
              }
              if (temp[0] >= 48 && temp[0] <= 57) {
                numberPlate.add(n[i]);
                j = n[i].length;
              }
              //print('RES: ${n[i]}');
            }
          }
        }
      } catch (e) {
        print(e);
        showToast(
            'CANT READ PROPERLY, PLEASE USE MANUAL CHECKER', Colors.redAccent,
            Icons.cancel);
      }
      // works for [LEC, 3378, 11]
      for (int i = 0; i < numberPlate.length; i++) {
        for (int j = 0; j < numberPlate[i].length; j++) {
          temp = numberPlate[i]
              .substring(j, j + 1)
              .codeUnits;
          if (temp[0] >= 48 && temp[0] <= 57) {
            if (numberPlate[i].codeUnits.length > 2) {
              String temp = numberPlate[i];
              numberPlate.remove(numberPlate[i]);
              numberPlate.add(temp);
            }
          }
        }
      }
    }

    void verify(List<String> n) async {
      sendToFb = n.join('-');
      getUserInfo(sendToFb);
      //print(sendToFb);
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

          _firestore.collection('TrafficMonitor').doc()
              .set({
            'number_plate': sendToFb,
            'type': vehicle_status,
            'time_date': getTime(),
          });

          showMyDialog('$carName has been Verified', 'tick');
          //showToast('$carName has been Verified', Colors.greenAccent, Icons.check);
        } else {
          //showToast('No record found', Colors.redAccent, Icons.clear);

          showMyDialog('NO RECORD FOUND', 'cross');
        }
      } catch (e) {
        showToast('$e', Colors.redAccent, Icons.clear);
      }
    }


    Future<void> processImage(InputImage inputImage) async {
      if (isBusy) return;
      isBusy = true;
      final recognisedText = await textDetector.processImage(inputImage);
      num = recognisedText.text.toString();
      print('$num');
      List<String> n = num.split('\n');
      //print(n);
      disPlate(n);
      print('FINAL: $numberPlate');
      verify(numberPlate);
      showToast('$numberPlate', Colors.greenAccent, Icons.check);
      numberPlate.clear();
      print('Found ${recognisedText.blocks.length} textBlocks');
      if (inputImage.inputImageData?.size != null &&
          inputImage.inputImageData?.imageRotation != null) {
        final painter = TextDetectorPainter(
            recognisedText,
            inputImage.inputImageData.size,
            inputImage.inputImageData.imageRotation);
        customPaint = CustomPaint(painter: painter);
      } else {
        customPaint = null;
      }
      isBusy = false;
      if (mounted) {
        setState(() {});
      }
    }
  }
