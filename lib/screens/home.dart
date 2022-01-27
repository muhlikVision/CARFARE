import 'package:carfare/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../genericWidgets.dart';

//Global

enum WAIT {
  DATA_IN_PROCESS,
  DATA_FETCHED,
  VEHICLE_INFO,
  PAYMENTS,
  SUPPORT,
  RESERVATIONS,
  SHOW_RESERVATIONS,
}

List<String> parkingFloorNames = [''];

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance; //auth data
  final _firestore = FirebaseFirestore.instance; //send and get data

  WAIT currentState = WAIT.DATA_IN_PROCESS;

  List<CustomTile> carsBox = [];
  List<CustomReserveTile> rBox = [];
  List<CustomFloorDisplayTile> rdBox = [];

  final floorCont = TextEditingController();
  final numpCont = TextEditingController();

  User loggedinUser;
  //userinfo
  String loggedInUid;
  String name;
  List<dynamic> myVehicles;

  //vehcile_info
  String v_name, v_type;
  bool v_status = false, v_verify = false;
  String status = ''; //temp

  //reservations
  String floorName, reserveTime, reserveCar;
  DateTime _dateTime;
  TimeOfDay _timeOfDay;

  String stDateTime, eDateTime;

  DateTime now = DateTime.now();
  String formattedDate =
      DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
  final DateFormat format = new DateFormat("yyyy-MM-dd hh:mm a");

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
    getUserInfo();
    checkReservationsCountAuto();
    getParkingCountStart();

    parkingFloorNames.clear();

    fToast = FToast();
    fToast.init(context);
  }

  // Future<void> makePayments() async {
  //   final url = Uri.parse('');
  // }
  Future<void> showMyDialog(String text, String anim) async {
    return showDialog(
      context: context,
      //barrierColor:  Colors.deepOrange.withOpacity(0.5),// user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Image.asset(
            'images/$anim.gif',
            height: 100.0,
            width: 100.0,
          ),
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

  String splitIt(String n) {
    List<String> lol = n.split(' ');
    return lol[0];
  }

  getParkingCountStart() async {
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
        final r = data['Reserved'];

        final fBox = CustomFloorDisplayTile(
          floorName: parkingFloorNames[i], count: c, reserve: r);
        rdBox.add(fBox);
      }
    }
    parkingFloorNames.clear();
    setState(() {
      currentState = WAIT.DATA_FETCHED;
    });

  }

  checkReservationsCountAuto() async {
    try {
      List<dynamic> docid;
      final QuerySnapshot result =
          await _firestore.collection('Reservations').get();

      if (result.docs.isNotEmpty) {
        //Map<String, dynamic> data = docSnapshot.data();
        final List<DocumentSnapshot> documents = result.docs;

        try {
          for (int i = 0; i < documents.length; i++) {
            print(documents[i].id);
            var docSnapshot = await _firestore
                .collection('Reservations')
                .doc(documents[i].id)
                .get();
            if (docSnapshot.exists) {
              Map<String, dynamic> data = docSnapshot.data();

              final uid = data['Uid'];
              final name = data['name'];
              final start = data['start'];
              final end = data['end'];
              final floor = data['floor'];
              final numplate = data['numberPlate'];
              final status = data['status'];

              if (status == true &&
                  DateTime.now().isAfter(DateTime.parse(end))) {
                try {
                  var docSnapshot =
                      await _firestore.collection('Reservations').get();
                  if (docSnapshot != null) {
                    //Map<String, dynamic> data = docSnapshot.data();

                    _firestore
                        .collection('Reservations')
                        .doc(documents[i].id) // <-- Document ID
                        .set({
                      'Uid': uid,
                      'name': name,
                      'numberPlate': numplate,
                      'start': start,
                      'end': end,
                      'floor': floor,
                      'status': false,
                    });
                  } else {
                    showToast('error', Colors.redAccent, Icons.clear);
                  }
                  decreaseReservationCount(floor);
                } catch (e) {
                  showToast('$e', Colors.redAccent, Icons.clear);
                }
              } else {}
            }
          }
          // setState(() {
          //   currentState = WAIT.DATA_FETCHED;
          // });
        } catch (e) {
          print(e);
          showToast('$e', Colors.redAccent, Icons.clear);
        }
      } else {
        print('nothing found');
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }

  decreaseReservationCount(floor) async {
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

            _firestore.collection('Parking Area').doc(floor) // <-- Document ID
                .set({
              'AreaTitle': at,
              'Reserved': rc - 1,
              'count': c,
            });
            showToast('reserve count updated', Colors.greenAccent, Icons.check);
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
        showToast('no record found', Colors.redAccent, Icons.clear);
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
    setState(() {
      currentState = WAIT.DATA_FETCHED;
    });
  }

  increaseReservationCount(floor) async {
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

            _firestore.collection('Parking Area').doc(floor) // <-- Document ID
                .set({
              'AreaTitle': at,
              'Reserved': rc + 1,
              'count': c,
            });
            showToast('reserve count updated', Colors.greenAccent, Icons.check);
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
        showToast('no record found', Colors.redAccent, Icons.clear);
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }

  saveReservationInfo(name, st, e, nump, uid, floorN) async {
    bool chk = true;
    try {
      var docSnapshot = await _firestore.collection('Reservations').get();
      if (docSnapshot != null) {
        //Map<String, dynamic> data = docSnapshot.data();
        setState(() {
          currentState = WAIT.RESERVATIONS;
        });

        _firestore.collection('Reservations').doc() // <-- Document ID
            .set({
          'name': name,
          'numberPlate': nump,
          'start': st,
          'end': e,
          'floor': floorN,
          'Uid': uid,
          'status': chk,
        });

        showMyDialog('$name \n$nump \nStart: $st \nEnd: $e \n$floorN', 'tick');
        //showToast('updated', Colors.greenAccent, Icons.check);
        floorCont.clear();
        numpCont.clear();

        this.floorName = null;
        this.reserveCar = null;
        this.reserveTime = null;
        this.stDateTime = null;
        this.eDateTime = null;

        increaseReservationCount(
            floorN); //updating reserve count in parking area table

      } else {
        showToast('error', Colors.redAccent, Icons.clear);
        setState(() {
          currentState = WAIT.RESERVATIONS;
        });
        //showMyDialog('NO RECORD FOUND','cross');
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
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

        setState(() {
          currentState = WAIT.RESERVATIONS;
        });
        print(parkingFloorNames);
        //parkingfloorsAdd();
        //parkingFloorNames.clear();
      } else {
        showToast('no data found', Colors.redAccent, Icons.clear);
      }
    } catch (e) {
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedinUser = user;
        loggedInUid = user.uid;
      }
    } catch (e) {
      print(e);
      showToast(e, Colors.redAccent, Icons.clear);
    }
  }

  getVehicleInfo() async {
    try {
      for (int i = 0; i < myVehicles.length; i++) {
        var docSnapshot =
            await _firestore.collection('Vehicles').doc(myVehicles[i]).get();
        if (docSnapshot.exists) {
          Map<String, dynamic> data = docSnapshot.data();

          final name = data['Name'];
          final status = data['status'];
          final type = data['type'];
          final verification = data['verification'];
          setState(() {
            v_name = name;
            v_status = status;
            v_type = type;
            v_verify = verification;
          });
          print('$v_name \n$v_status \n$v_type \n$v_verify');
          final carBox = CustomTile(
            carName: v_name,
            status: v_status,
            verify: v_verify,
            type: v_type,
            numberPlate: myVehicles[i],
          );
          carsBox.add(carBox);
        }
      }
    } catch (e) {
      print(e);
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }

  getUserInfo() async {
    try {
      var docSnapshot = await _firestore
          .collection('Users')
          .doc('Student')
          .collection('Students')
          .doc(loggedInUid)
          .get();
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data();

        final tname = data['Name']['first'];
        final lname = data['Name']['last'];
        final vehicles = data['vehicles'];

        myVehicles = vehicles; //vehicles
        name = '$tname $lname'; //username

        if (myVehicles.length > 0) {
          getVehicleInfo();
        }
        showToast('LOGGED IN', Colors.lightGreenAccent, Icons.check);
        return name;
      } else {
        var docSnapshotTwo =
            await _firestore.collection('Users').doc('Student').get();
        if (docSnapshotTwo.exists) {
          Map<String, dynamic> data = docSnapshotTwo.data();

          final mail_uid = data[loggedInUid]; //USerName

          if (mail_uid != null) {
            loggedInUid = mail_uid;
            getUserInfo();
          } else {
            print('phoneAuth uid not found');
            setState(() {
              currentState = WAIT.DATA_FETCHED;
            });
            Navigator.pop(context);
            showToast(
                'Phone Number NOT registered', Colors.redAccent, Icons.clear);
          }
        }
      }
    } catch (e) {
      print(e);
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }

  vehicles(context) {
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
              setState(() {
                currentState = WAIT.DATA_FETCHED;
              });
            },
          ),
          title: Text('My Vehicles'),
          elevation: 20,
          backgroundColor: color,
        ),
        body: ListView(
          shrinkWrap: true,
          children: carsBox,
        ),
      ),
    );
  }

  reservations(context) {
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
                  currentState = WAIT.DATA_FETCHED;
                });
                parkingFloorNames.clear();
              },
            ),
            title: Text('Reservations'),
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
                    Center(
                      child: Text(
                        "SELECT Time and Date",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ButtonBuilder(
                            onPress: () async {
                              bool chk = false;
                              showTimePicker(
                                context: context,
                                initialTime: _timeOfDay == null
                                    ? TimeOfDay.fromDateTime(
                                        _timeOfDay ?? DateTime.now())
                                    : _timeOfDay,
                              ).then((time) {
                                setState(() {
                                  _timeOfDay = time;

                                  print(_timeOfDay.format(context));

                                  if (_dateTime != null && _timeOfDay != null) {
                                    final String dateTimeString =
                                        splitIt(_dateTime.toString()) +
                                            " " +
                                            _timeOfDay
                                                .format(context)
                                                .toString();
                                    print(dateTimeString);
                                    try {
                                      print(format.parse(dateTimeString));
                                      stDateTime = format
                                          .parse(dateTimeString)
                                          .toString();
                                    } catch (e) {
                                      print(e);
                                    }
                                  }
                                });
                              });
                              showDatePicker(
                                      context: context,
                                      initialDate: _dateTime == null
                                          ? DateTime.now()
                                          : _dateTime,
                                      firstDate: DateTime(2001),
                                      lastDate: DateTime(2024))
                                  .then((date) {
                                setState(() {
                                  _dateTime = date;
                                  print(_dateTime);
                                });
                              });
                            },
                            color: Colors.greenAccent,
                            text: 'START DATE/TIME'),
                        ButtonBuilder(
                            onPress: () async {
                              bool chk = false;
                              showTimePicker(
                                context: context,
                                initialTime: _timeOfDay == null
                                    ? TimeOfDay.fromDateTime(
                                        _timeOfDay ?? DateTime.now())
                                    : _timeOfDay,
                              ).then((time) {
                                setState(() {
                                  _timeOfDay = time;

                                  print(_timeOfDay.format(context));

                                  if (_dateTime != null && _timeOfDay != null) {
                                    final String dateTimeString =
                                        splitIt(_dateTime.toString()) +
                                            " " +
                                            _timeOfDay
                                                .format(context)
                                                .toString();
                                    print(dateTimeString);
                                    try {
                                      print(format.parse(dateTimeString));
                                      eDateTime = format
                                          .parse(dateTimeString)
                                          .toString();
                                    } catch (e) {
                                      print(e);
                                    }
                                  }
                                });
                              });
                              showDatePicker(
                                      context: context,
                                      initialDate: _dateTime == null
                                          ? DateTime.now()
                                          : _dateTime,
                                      firstDate: DateTime(2001),
                                      lastDate: DateTime(2024))
                                  .then((date) {
                                setState(() {
                                  _dateTime = date;
                                  print(_dateTime);
                                });
                              });
                            },
                            color: Colors.redAccent,
                            text: 'END DATE/TIME'),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Available floors for reservations below',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontStyle: FontStyle.normal),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$parkingFloorNames',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontStyle: FontStyle.normal),
                      ),
                    ),
                    SizedBox(
                      height: 24.0,
                    ),
                    Center(
                      child: Text(
                        "Enter Floor Name from the list given above",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    InputField(
                      onChange: (value) {
                        floorName = value;
                      },
                      bcolor: Colors.blue,
                      text: 'B1, G, H2 etc.',
                      type: TextInputType.name,
                      tec: floorCont,
                      //tec: nameCont,
                    ),
                    SizedBox(
                      height: 24.0,
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    Center(
                      child: Text(
                        "Enter The numberplate of your car you want to reserve",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Center(
                      child: Text(
                        "$myVehicles",
                        style: TextStyle(color: Colors.white,fontSize: 18,),
                      ),
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    InputField(
                      onChange: (value) {
                        reserveCar = value;
                      },
                      bcolor: Colors.blue,
                      text: 'ABC-12-3456',
                      type: TextInputType.name,
                      tec: numpCont,
                      //tec: nameCont,
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    ButtonBuilder(
                        onPress: () async {
                          bool chk = false;
                          bool chk2 = false;
                          if (name != null &&
                              reserveCar != null &&
                              floorName != null) {
                            for (int i = 0; i < myVehicles.length; i++) {
                              if (reserveCar.toUpperCase() == myVehicles[i]) {
                                chk = true;
                                break;
                              }
                            }
                            for (int i = 0; i < parkingFloorNames.length; i++) {
                              if (floorName.toUpperCase() ==
                                  parkingFloorNames[i].toUpperCase()) {
                                chk2 = true;
                                break;
                              }
                            }
                            if (chk == true && chk2 == true) {
                              if (DateTime.parse(stDateTime)
                                      .isAfter(DateTime.now()) &&
                                  DateTime.parse(eDateTime)
                                      .isAfter(DateTime.parse(stDateTime))) {
                                setState(() {
                                  currentState = WAIT.DATA_IN_PROCESS;
                                });
                                saveReservationInfo(
                                    name,
                                    stDateTime,
                                    eDateTime,
                                    reserveCar.toUpperCase(),
                                    loggedInUid,
                                    floorName.toUpperCase());
                              } else
                                showToast('Time not selected correctly',
                                    Colors.redAccent, Icons.clear);
                            } else {
                              showToast('Floor or Number plate Incorrect',
                                  Colors.redAccent, Icons.clear);
                            }
                          } else {
                            showToast(
                                'fields empty', Colors.redAccent, Icons.clear);
                          }
                        },
                        color: Colors.blue,
                        text: 'RESERVE'),
                    SizedBox(
                      height: 24.0,
                    ),
                  ]))),
    );
  }

  getReservationInfo() async {
    try {
      List<dynamic> docid;
      final QuerySnapshot result =
          await _firestore.collection('Reservations').get();

      if (result.docs.isNotEmpty) {
        //Map<String, dynamic> data = docSnapshot.data();
        final List<DocumentSnapshot> documents = result.docs;

        try {
          for (int i = 0; i < documents.length; i++) {
            print(documents[i].id);
            var docSnapshot = await _firestore
                .collection('Reservations')
                .doc(documents[i].id)
                .get();
            if (docSnapshot.exists) {
              Map<String, dynamic> data = docSnapshot.data();

              final uid = data['Uid'];
              final name = data['name'];
              final start = data['start'];
              final end = data['end'];
              final floor = data['floor'];
              final numplate = data['numberPlate'];

              if (loggedInUid == uid) {
                final rsBox = CustomReserveTile(
                  floorName: floor.toString(),
                  userName: name.toString(),
                  startTime: start.toString(),
                  endTime: end.toString(),
                  numberPlate: numplate.toString(),
                );
                rBox.add(rsBox);
              }
            }
          }
          setState(() {
            currentState = WAIT.SHOW_RESERVATIONS;
          });
        } catch (e) {
          print(e);
          showToast('$e', Colors.redAccent, Icons.clear);
        }
      } else {
        print('nothing found');
      }
    } catch (e) {
      print(e);
      showToast('$e', Colors.redAccent, Icons.clear);
    }
  }

  checkReservations(context) {
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
              setState(() {
                currentState = WAIT.DATA_FETCHED;
              });
              rBox.clear();
            },
          ),
          title: Text('My Reservations'),
          elevation: 20,
          backgroundColor: color,
        ),
        body: ListView(
          shrinkWrap: true,
          children: rBox,
        ),
      ),
    );
  }

  payments(context){
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
              setState(() {
                currentState = WAIT.DATA_FETCHED;
              });
            },
          ),
          title: Text('Payments (SOON)'),
          elevation: 20,
          backgroundColor: color,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
          Flexible(
          child: Hero(
            tag: 'logo',
            child: Container(
              height: 200.0,
              child: Image.asset('images/stripe.png'),
            ),
          ),
        ),
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('images/sada.png'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  homeScreen(context) {
    return WillPopScope(
      onWillPop: () async {
        return;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Color(0xFF141313),
          appBar: AppBar(
            title: Text('$name'),
            elevation: 20,
            backgroundColor: color,
          ),
          drawer: Drawer(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const DrawerHeader(
                  decoration: BoxDecoration(
                    image:
                        DecorationImage(image: AssetImage('images/logo.jpg')),
                    color: color,
                  ),
                  child: Text('Version 1.0', style: TextStyle(color: Colors.white,)),
                ),
                ListTile(
                  title: const Text('Vehicle Details', style: TextStyle(color: Colors.white,)),
                  trailing: Icon(
                    Icons.airport_shuttle,
                    color: Colors.red,
                  ),
                  focusColor: color,
                  onTap: () {
                    setState(() {
                      currentState = WAIT.VEHICLE_INFO;
                      status = 'vehicle details pushed';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Payments',style: TextStyle(color: Colors.white,)),
                  trailing: Icon(
                    Icons.money,
                    color: Colors.red,
                  ),
                  focusColor: color,
                  onTap: () {
                    // Update the state of the app.
                    setState(() {
                      currentState = WAIT.PAYMENTS;
                      status = 'payments pushed';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Contact Support',style: TextStyle(color: Colors.white,)),
                  trailing: Icon(
                    Icons.phone,
                    color: Colors.red,
                  ),
                  focusColor: color,
                  onTap: () {
                    // Update the state of the app.
                    Navigator.pop(context);
                  },
                ),
                Divider(
                  color: Colors.deepOrange,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ListTile(
                      title: const Text('LOGOUT',style: TextStyle(color: Colors.white,)),
                      trailing: Icon(
                        Icons.logout_sharp,
                        color: Colors.red,
                      ),
                      focusColor: color,
                      onTap: () async {
                        SharedPreferences pref =
                            await SharedPreferences.getInstance();
                        pref.remove('email');
                        showToast(
                            'LOGGED OUT', Colors.lightBlueAccent, Icons.check);
                        _auth.signOut();
                        Navigator.popAndPushNamed(context, LoginScreen.id);
                        //Navigator.pop(context);
                        parkingFloorNames.clear();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.home),
                text: 'HOME',
              ),
              Tab(
                icon: Icon(Icons.car_rental),
                text: 'RESERVATIONS',
              ),
            ],
            labelColor: Colors.deepOrange,
            indicatorColor: Colors.deepOrange,
          ),
          body: TabBarView(
            children: [
              WillPopScope(
                onWillPop: () async {
                  return;
                },
                child: Scaffold(
                  backgroundColor: Color(0xFF141313),
                  body: ListView(
                    shrinkWrap: true,
                    children: rdBox,
                  ),
                ),
              ),
              ModalProgressHUD(
                  inAsyncCall: false,
                  color: Colors.deepOrange,
                  progressIndicator: CircularProgressIndicator(
                    color: Colors.deepOrange,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: 8.0,
                          ),
                          ButtonBuilder(
                              onPress: () {
                                setState(() {
                                  currentState = WAIT.DATA_IN_PROCESS;
                                });
                                getParkingCount();
                              },
                              color: Colors.blue,
                              text: 'RESERVE VEHICLE'),
                          SizedBox(
                            height: 8.0,
                          ),
                          ButtonBuilder(
                              onPress: () {
                                setState(() {
                                  currentState = WAIT.DATA_IN_PROCESS;
                                });
                                getReservationInfo();
                              },
                              color: Colors.blue,
                              text: 'CHECK MY RESERVATIONS'),
                        ]),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentState == WAIT.DATA_IN_PROCESS) {
      return ModalProgressHUD(
        inAsyncCall: true,
        color: Colors.deepOrange,
        progressIndicator: CircularProgressIndicator(
          color: Colors.deepOrange,
        ),
        child: Container(),
      );
    } else if (currentState == WAIT.VEHICLE_INFO) {
      return vehicles(context);
    } else if (currentState == WAIT.RESERVATIONS) {
      return reservations(context);
    } else if (currentState == WAIT.SHOW_RESERVATIONS) {
      return checkReservations(context);
    } else if (currentState == WAIT.PAYMENTS) {
      return payments(context);
    } else {
      return homeScreen(context);
    }
  }
}
