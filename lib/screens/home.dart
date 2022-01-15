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
  String floorName, reserveTime;
  DateTime _dateTime;
  TimeOfDay _timeOfDay;

  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
  final DateFormat format = new DateFormat("yyyy-MM-dd hh:mm a");

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
    getUserInfo();
    fToast = FToast();
    fToast.init(context);
  }

  // Future<void> makePayments() async {
  //   final url = Uri.parse('');
  // }

  String splitIt(String n)
  {
    List<String> lol = n.split(' ');
    return lol[0];
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
      }
      else {
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
    try{
      for(int i = 0 ; i < myVehicles.length; i++)
        {
          var docSnapshot = await _firestore
              .collection('Vehicles')
              .doc(myVehicles[i])
              .get();
          if (docSnapshot.exists) {
            Map<String, dynamic> data = docSnapshot.data();

            final name = data['Name'];
            final status = data['status'];
            final type = data['type'];
            final verification = data['verification'];
            setState(() {
              v_name = name; v_status = status; v_type = type; v_verify = verification;
            });
            print('$v_name \n$v_status \n$v_type \n$v_verify');
            final carBox = CustomTile(carName: v_name,status: v_status,verify: v_verify, type: v_type, numberPlate: myVehicles[i],);
            carsBox.add(carBox);
          }
        }
    }
    catch(e)
    {
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
        name = '$tname $lname';//username

        if(myVehicles.length > 0) {
          getVehicleInfo();
        }
        setState(() {
          currentState = WAIT.DATA_FETCHED;
          showToast('LOGGED IN', Colors.lightGreenAccent, Icons.check);
        });

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
                        'Available floors for reservations below\n $parkingFloorNames',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontStyle: FontStyle.normal),
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
                      //tec: nameCont,
                    ),
                    SizedBox(
                      height: 24.0,
                    ),
                    Center(
                      child: Text(
                        "Enter Time and Date",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    ButtonBuilder(
                        onPress: () async {
                          showDatePicker(
                              context: context,
                              initialDate: _dateTime == null ? DateTime.now() : _dateTime,
                              firstDate: DateTime(2001),
                              lastDate: DateTime(2024)
                          ).then((date) {
                            setState(() {
                              _dateTime = date;
                              print(_dateTime);
                            });
                          });

                        }, color: Colors.green, text: 'SELECT DATE'),
                    SizedBox(
                      height: 15.0,
                    ),
                    ButtonBuilder(
                        onPress: () async {
                          showTimePicker(
                              context: context,
                              initialTime: _timeOfDay == null ? TimeOfDay.fromDateTime(_timeOfDay ?? DateTime.now()) : _timeOfDay,

                          ).then((time) {
                            setState(() {
                              _timeOfDay = time;
                              print(_timeOfDay.format(context));
                            });
                          });

                        }, color: Colors.green, text: 'SELECT TIME'),
                    SizedBox(
                      height: 15.0,
                    ),

                    ButtonBuilder(
                        onPress: () async {

                          if(_dateTime != null && _timeOfDay != null) {
                            final String dateTimeString = splitIt(_dateTime.toString()) + " " + _timeOfDay.format(context).toString();
                            print(dateTimeString);
                            try {
                              print(format.parse(dateTimeString));
                            }
                            catch(e) {
                            print(e);
                            }
                          }
                        }, color: Colors.green, text: 'SELECT TIME'),
                    SizedBox(
                      height: 15.0,
                    ),
                    InputField(
                      onChange: (value) {
                        //numPlate = value;
                      },
                      bcolor: Colors.blue,
                      text: 'ABC-XX-XXXX',
                      type: TextInputType.name,
                      //tec: numPlateCont,
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
                        //ph = value;
                      },
                      bcolor: Colors.blue,
                      text: '+92-XXX-XXXXXXX',
                      type: TextInputType.phone,
                      //tec: phCont,
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
                        //pay = int.parse(value);

                      },
                      bcolor: Colors.green,
                      text: '0.0',
                      type: TextInputType.number,
                      //tec: payCont,
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
                        //fac = value;
                      },
                      bcolor: Colors.blue,
                      text: 'faculty name',
                      type: TextInputType.text,
                      //tec: facCont,
                    ),
                    SizedBox(
                      height: 24.0,
                    ),
                    ButtonBuilder(
                        onPress: () async {
                          // print('$name, $ph, $fac, $pay, $numPlate');
                          // if(name != null && numPlate != null && ph != null && fac != null) {
                          //   saveGuestInfo(name, numPlate.toUpperCase(), ph, pay, fac);
                          //   setState(() {
                          //     currentState = STATE.WAIT;
                          //   });
                          // }
                          // else
                          //   showToast('Fields Empty', Colors.redAccent, Icons.clear);

                        }, color: Colors.green, text: 'SAVE INFO'),
                    SizedBox(
                      height: 24.0,
                    ),
                  ]))),
    );
  }
  checkReservations(context){

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
                  child: Text('beta.v1'),
                ),
                ListTile(
                  title: const Text('Vehicle Details'),
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
                  title: const Text('Payments'),
                  trailing: Icon(
                    Icons.money,
                    color: Colors.red,
                  ),
                  focusColor: color,
                  onTap: () {
                    // Update the state of the app.
                    setState(() {
                      status = 'payments pushed';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Contact Support'),
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
                      title: const Text('LOGOUT'),
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
              ModalProgressHUD(
                inAsyncCall: false,
                child: Center(
                  child: Container(
                    color: color,
                    child: Row(
                    ),
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
                          ButtonBuilder(onPress: (){
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
                          ButtonBuilder(onPress: (){

                          },
                              color: Colors.blue,
                              text: 'CHECK MY RESERVATIONS'),
                        ]
                    ),
                )
              ),

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
    } else {
      return homeScreen(context);
    }
  }
}
