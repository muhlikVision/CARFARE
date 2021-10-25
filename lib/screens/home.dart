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

//Global

enum WAIT {
  DATA_IN_PROCESS,
  DATA_FETCHED,
  VEHICLE_INFO,
  PAYMENTS,
  SUPPORT,
}

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance; //auth data
  final _firestore = FirebaseFirestore.instance; //send and get data

  WAIT currentState = WAIT.DATA_IN_PROCESS;

  User loggedinUser;
  //userinfo
  String loggedInUid;
  String name;
  List<dynamic> myVehicles;


  String status = ''; //temp

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
    getUserInfo();
    fToast = FToast();
    fToast.init(context);
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
            print('$name $status $type $verification');
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
                    child: Text(
                      status,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Icon(Icons.developer_board),
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
    } else {
      return homeScreen(context);
    }
  }
}
