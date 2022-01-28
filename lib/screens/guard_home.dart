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
List<String> trafficMonitorDocNames = [''];

String floorSelected;
String tempGetNumberPlate;
String finalFloor;

enum STATE {
  MAIN,
  SCAN,
  TOKEN,
  CURRENT_STATUS,
  WAIT,
}

class GuardScreen extends StatefulWidget {
  static const String id = 'guard_screen';

  @override
  TextDetectorViewState createState() => TextDetectorViewState();
}

//TODO:...............................................
//TODO: ADD GUEST TOKEN AND reservation count update

class TextDetectorViewState extends State<GuardScreen> {
  final _auth = FirebaseAuth.instance; //auth data
  final _firestore = FirebaseFirestore.instance;
  TextDetector textDetector = GoogleMlKit.vision.textDetector();
  bool isBusy = false;
  CustomPaint customPaint;

  final nameCont = TextEditingController();
  final phCont = TextEditingController();
  final payCont = TextEditingController();
  final facCont = TextEditingController();
  final numPlateCont = TextEditingController();

  final fCont = TextEditingController();

  String sendToFb;
  List<CustomFloorTile> floorsBox = [];
  int floorCount;
  STATE currentState = STATE.MAIN;
  String name, numPlate, ph, fac;
  int pay = 0;



  @override
  void dispose() async {
    super.dispose();
    await textDetector.close();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    parkingFloorNames.clear();
    fToast = FToast();
    fToast.init(context);
  }


  getTrafficDocIdCount() async {
    try {
      final QuerySnapshot result =
      await _firestore.collection('TrafficMonitor').get();
      final List<DocumentSnapshot> documents = result.docs;

      if (documents != null) {
        //documents.forEach((data) => print(data.id));
        documents.forEach((data) {
          trafficMonitorDocNames.add(data.id);
        });
        print(trafficMonitorDocNames);

      }
      else {
        showToast('no data found', Colors.redAccent, Icons.clear);
      }
      setState(() {
        currentState = STATE.SCAN;
      });
    } catch (e) {
      setState(() {
        currentState = STATE.MAIN;
      });
      showToast('$e', Colors.redAccent, Icons.clear);
    }
    showToast('Traffic Monitor Data fetched', Colors.redAccent, Icons.clear);
  } //only doc id's

  callBackState(c, f, co){
    print('current: $f $co');
      setState(() {
        currentState = STATE.WAIT;
        floorsBox.clear();
      });
      updateParkingCount(f, co);
      //will update the reserve count
  }


  Future<void> showMyDialog(String text) async {
    return showDialog(
      context: context,
      //barrierColor:  Colors.deepOrange.withOpacity(0.5),// user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0)),
          title: null,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Center(child: Text('Please Select the floor')),
                Center(child: Text('')),
                Center(child: Text('$parkingFloorNames')),
                Center(child: Text('')),
                Center(child:
                InputField(
                  onChange: (value) {
                    floorSelected = value;
                  },
                  bcolor: Colors.deepOrange,
                  text: 'Enter Floor',
                  tec: fCont,
                  type: TextInputType.text,
                ),

                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                bool chk = false;
                if(floorSelected != null){
                  for(int i = 0; i < parkingFloorNames.length;i++)
                    {
                      if(floorSelected.toUpperCase() == parkingFloorNames[i])
                        chk = true;
                    }
                }
                if(chk == true){
                  //updateParkingCountAuto(floorSelected.toUpperCase(), vehicle_status);
                  Navigator.of(context, rootNavigator: true).pop();
                  showToast('Floor Selected, Now SCAN', Colors.greenAccent, Icons.check);
                  setState(() {
                    finalFloor = floorSelected;
                  });
                }
                else
                  {
                    showToast('Wrong Input', Colors.redAccent, Icons.clear);
                  }
                fCont.clear();
                floorSelected = null;
              },
            ),
          ],
        );
      },
    );
  } //with input field
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
  } //simple

  saveGuestInfo(name, numPlate, ph, pay,fac) async {
    String latestTime = getTime();
    try {
      var docSnapshot =
      await _firestore.collection('Guest').get();
      if (docSnapshot != null) {
        //Map<String, dynamic> data = docSnapshot.data();
        setState(() {
          currentState = STATE.TOKEN;
        });

        _firestore.collection('Guest').doc('$latestTime') // <-- Document ID
            .set({
          'name' : name,
          'numberPlate' : numPlate,
          'phoneNo': ph,
          'payment': pay,
          'purpose': fac,
          'time': latestTime,
        });

        showMyWrongDialog('$name | has been registered','tick');
        //showToast('updated', Colors.greenAccent, Icons.check);
        nameCont.clear();
        phCont.clear();
        payCont.clear();
        facCont.clear();
        numPlateCont.clear();
        this.name = null;
        this.numPlate = null;
        this.ph = null;
        this.pay = null;
        this.fac = null;

      } else {
        showToast('error', Colors.redAccent, Icons.clear);

        //showMyDialog('NO RECORD FOUND','cross');
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }

  updateParkingCount (floorName,int count) async {
    try {
      var docSnapshot =
      await _firestore.collection('Parking Area').doc(floorName).get();
      if (docSnapshot.exists) {
        //Map<String, dynamic> data = docSnapshot.data();


        _firestore.collection('Parking Area').doc(floorName) // <-- Document ID
            .set({
          'AreaTitle' : floorName,
          'Reserved' : 0,
          'count': count,
        });

        //showMyDialog('$carName has been Verified','tick');
        showToast('updated', Colors.greenAccent, Icons.check);
        getParkingCount();
      } else {
        showToast('error', Colors.redAccent, Icons.clear);

        //showMyDialog('NO RECORD FOUND','cross');
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }

  } //for manual buttons

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
  } //only doc id's
  parkingfloorsAdd() async {
    for (int i = 0; i < parkingFloorNames.length; i++) {
      var docSnapshot = await _firestore
          .collection('Parking Area')
          .doc(parkingFloorNames[i])
          .get();
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data();

        final c = data['count'];
        final r = data['Reserved'];
        setState(() {
          floorCount = c;
        });
        final fBox = CustomFloorTile(
          floorName: parkingFloorNames[i], reserved: r.toString(), count: floorCount,callBackState: callBackState,);
        floorsBox.add(fBox);
      }
    }
    parkingFloorNames.clear();
    setState(() {
      currentState = STATE.CURRENT_STATUS;
    });
  }

  //for scan context
  tempGetParkingCount() async {
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
      }
      else {
        showToast('no data found', Colors.redAccent, Icons.clear);
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
    if(vehicle_status == 'entry'){
      showMyDialog('');
    }
    else
      {
        showToast('floor not selected', Colors.redAccent, Icons.clear);
      }

  } //only doc id's

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
                  'time_date' : getTime(),
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
  } //for auto on scan

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
              leading:
              IconButton(
                  icon: Icon(
                    Icons.logout_sharp,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    SharedPreferences pref = await SharedPreferences.getInstance();
                    pref.remove('email');
                    showToast('LOGGED OUT', Colors.lightBlueAccent, Icons.check);
                    _auth.signOut();
                    Navigator.popAndPushNamed(context, LoginScreen.id);
                    //Navigator.pushNamed(context, LoginScreen.id);
                  }),
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
                          onPress: () async {
                            setState(() {
                              currentState = STATE.SCAN;
                              vehicle_status = 'entry';
                            });
                            tempGetParkingCount();
                            //getTrafficDocIdCount();

                            showToast('$vehicle_status', Colors.blueAccent,
                                Icons.check);
                          }, color: Colors.green, text: 'ENTRY'),
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () async {
                            setState(() {
                              currentState = STATE.WAIT;
                              vehicle_status = 'exit';
                            });
                            tempGetParkingCount();
                            getTrafficDocIdCount();

                            showToast('$vehicle_status', Colors.blueAccent,
                                Icons.check);
                          }, color: Colors.red, text: 'EXIT'),
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () async {
                            parkingFloorNames.clear(); 

                            setState(() {
                              currentState = STATE.WAIT;
                            });
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
                  this.name = null;
                  this.numPlate = null;
                  this.ph = null;
                  this.pay = null;
                  this.fac = null;
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
                          name = value;
                        },
                        bcolor: Colors.blue,
                        text: 'Name here',
                        type: TextInputType.name,
                        tec: nameCont,
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
                          numPlate = value;
                        },
                        bcolor: Colors.blue,
                        text: 'ABC-XX-XXXX',
                        type: TextInputType.name,
                        tec: numPlateCont,
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
                          ph = value;
                        },
                        bcolor: Colors.blue,
                        text: '+92-XXX-XXXXXXX',
                        type: TextInputType.phone,
                        tec: phCont,
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
                          pay = int.parse(value);
                          print(pay);
                        },
                        bcolor: Colors.green,
                        text: '0.0',
                        type: TextInputType.number,
                        tec: payCont,
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
                          fac = value;
                        },
                        bcolor: Colors.blue,
                        text: 'faculty name',
                        type: TextInputType.text,
                        tec: facCont,
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      ButtonBuilder(
                          onPress: () async {
                            print('$name, $ph, $fac, $pay, $numPlate');
                            if(name != null && numPlate != null && ph != null && fac != null) {
                              saveGuestInfo(name, numPlate.toUpperCase(), ph, pay, fac);
                              setState(() {
                                currentState = STATE.WAIT;
                              });
                            }
                            else
                              showToast('Fields Empty', Colors.redAccent, Icons.clear);

                          }, color: Colors.green, text: 'SAVE INFO'),
                      SizedBox(
                        height: 24.0,
                      ),
                    ]))),
      );
    }
    scan(context) {
      return CameraView(
        title: 'SCAN NUMBER PLATE ($vehicle_status)',
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
            parkingFloorNames.clear();
            trafficMonitorDocNames.clear();
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
      if (currentState == STATE.WAIT) {
        return ModalProgressHUD(
          inAsyncCall: true,
          opacity: 1,
          color: Colors.white10,
          progressIndicator: CircularProgressIndicator(
            color: Colors.deepOrange,
          ),
          child: Container(),
        );
      }
      else if (currentState == STATE.MAIN) {
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

          if(vehicle_status == 'entry') {
            _firestore.collection('TrafficMonitor').doc()
                .set({
              'number_plate': sendToFb,
              'type': vehicle_status,
              'time_date': getTime(),
              'floor': finalFloor,
              'status': true,
            });
          }

          setState(() {
            tempGetNumberPlate = sendToFb;
          });

          updateParkingCountAuto(finalFloor.toUpperCase(), vehicle_status);

          showMyWrongDialog('$carName has been Verified\n\nFloor | $finalFloor', 'tick');
          //showToast('$carName has been Verified', Colors.greenAccent, Icons.check);
        } else {
          //showToast('No record found', Colors.redAccent, Icons.clear);

          showMyWrongDialog('NO RECORD FOUND', 'cross');
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
