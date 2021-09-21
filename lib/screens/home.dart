import 'package:carfare/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../genericWidgets.dart';

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance; //auth data
  final _firestore = FirebaseFirestore.instance; //send and get data

  String getUser = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  Future<String> getLoggedUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    getUser = pref.getString('email');
    return getUser;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Color(0xFF141313),
          appBar: AppBar(
            title: Text('${_auth.currentUser.email}'),
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
                  title: const Text('User Info'),
                  trailing: Icon(
                    Icons.person,
                    color: Colors.red,
                  ),
                  focusColor: color,
                  onTap: () {
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
                        showToast('LOGGED OUT', Colors.lightBlueAccent,
                            Icons.check);
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
                      child: ButtonBuilder(
                          onPress: () async {
                            //Navigator.pushNamed(context, LoginScreen.id);
                          },
                          color: Colors.lightBlueAccent,
                          text: 'logout')),
                ),
              ),
              Icon(Icons.directions_transit),
            ],
          ),
        ),
      ),
    );
  }
}
