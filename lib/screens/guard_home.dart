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


class GuardScreen extends StatefulWidget {
  static const String id = 'guard_screen';
  @override
  _TextDetectorViewState createState() => _TextDetectorViewState();
}

class _TextDetectorViewState extends State<GuardScreen> {
  final _auth = FirebaseAuth.instance; //auth data
  final _firestore = FirebaseFirestore.instance;
  TextDetector textDetector = GoogleMlKit.vision.textDetector();
  bool isBusy = false;
  CustomPaint customPaint;

  String sendToFb;

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

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'CARFARE Testing Phase',
      customPaint: customPaint,
      onImage: (inputImage) async {
        await processImage(inputImage);
      },
    );
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
                }
                else if (n[i].substring(l, l + 1) == ' ') {
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
    }
    catch(e)
    {
      print(e);
      showToast('$e', Colors.redAccent, Icons.cancel);
    }
    // works for [LEC, 3378, 11]
    for (int i = 0; i < numberPlate.length; i++) {
      for (int j = 0; j < numberPlate[i].length; j++) {
        temp = numberPlate[i].substring(j, j + 1).codeUnits;
        if(temp[0] >= 48 && temp[0] <= 57){
          if (numberPlate[i].codeUnits.length > 2) {
            String temp = numberPlate[i];
            numberPlate.remove(numberPlate[i]);
            numberPlate.add(temp);
          }
        }
      }
    }
  }

  void verify(List<String> n)async{
    sendToFb = n.join('-');
    getUserInfo();
    print(sendToFb);
  }
  getUserInfo() async {
    try {
      var docSnapshot = await _firestore
          .collection('Vehicles')
          .doc(sendToFb)
          .get();
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data();

        final carName = data['Name'];
        // setState(() {
        //   currentState = WAIT.DATA_FETCHED;
        // });
        showToast('$carName has been Verified', Colors.greenAccent, Icons.check);
      }
      else
        {
          showToast('No record found', Colors.redAccent, Icons.clear);
        }
    } catch (e) {
      showToast(e, Colors.redAccent, Icons.clear);
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
