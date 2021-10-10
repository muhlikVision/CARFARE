import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'camera_view.dart';
import 'painters/text_detector_painter.dart';

String num = '';
int x = 0;
List<String> numberPlate = [];

FToast fToast;

class TextDetectorView extends StatefulWidget {
  @override
  _TextDetectorViewState createState() => _TextDetectorViewState();
}

class _TextDetectorViewState extends State<TextDetectorView> {
  TextDetector textDetector = GoogleMlKit.vision.textDetector();
  bool isBusy = false;
  CustomPaint customPaint;

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
      onImage: (inputImage) {
        processImage(inputImage);
      },
    );
  }

  showToast(String text) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.redAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check),
          SizedBox(
            width: 12.0,
          ),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),),
        ],
      ),
    );


    fToast.showToast(
      child: toast,
      gravity: ToastGravity.CENTER,
      toastDuration: Duration(seconds: 7),
    );
  }

  List<String> func(String n) {
    List<String> lel = [];
    int start = 0;
    for (int j = 0; j < n.length; j++) {
      if (n[j] == '-' || n[j] == ' ' || n[j] == '\n' || j == n.length - 1) {
        if (j == n.length - 1) {
          j++;
        }
        lel.add(n.substring(start, j));
        start = j + 1;
      }
    }
    return lel;
  }

  void disPlate(List<String> n) {
    //LEB 15,1234

    List<int> temp;

    for (int i = 0; i < n.length; i++) {
      for (int j = 0; j < n[i].length; j++) {
        temp = n[i].substring(j, j + 1).codeUnits;
        //print('ASCII: $temp of ${n[i].substring(j, j + 1)}');
        if (n[i].substring(j, j + 1) == '-' ||
            n[i].substring(j, j + 1) == ' ' ||
            n[i].substring(j, j + 1) == 'L' ||
            temp[0] >= 48 && temp[0] <= 57) {
          if (n[i].substring(j, j + 1) == ' ') {
            List<String> tempS = n[i].split(' ');
            print('tempS: $tempS');
            numberPlate.add(tempS[0]);
            numberPlate.add(tempS[1]);
            tempS.clear();
            j = n[i].length;
          }
          if (n[i].substring(j, j + 1) == 'L') {
            List<String> tempS = [];
            for(int l = 0; l < n[i].length; l++)
              {
                if(n[i].substring(l, l + 1) == '-')
                  {
                    tempS = n[i].split('-');
                    l = n[i].length;
                  }
                else if (n[i].substring(l, l + 1) == ' ')
                  {
                    tempS = n[i].split(' ');
                    l = n[i].length;
                  }
              }
            print('tempSL: $tempS');
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
            print('tempS-: $tempS');
            numberPlate.add(tempS[0]);
            numberPlate.add(tempS[1]);
            tempS.clear();
            j = n[i].length;
          }
          if (temp[0] >= 48 && temp[0] <= 57) {
            numberPlate.add(n[i]);
            j = n[i].length;
          }
          print('RES: ${n[i]}');
        }
      }
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

  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final recognisedText = await textDetector.processImage(inputImage);
    num = recognisedText.text.toString();
    print('$num');
    List<String> n = num.split('\n');
    print(n);
    disPlate(n);
    print(numberPlate);
    showToast('Vehicle Verified\n${numberPlate.toString()}');
    // n = [''];
    numberPlate.clear();
    // x = 0;
    //print(func(num));
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
