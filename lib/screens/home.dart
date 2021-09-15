import 'package:carfare/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(color: Colors.white,
          child: ButtonBuilder(onPress: () async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.remove('email');
        showToast('LOGGED OUT', Colors.lightBlueAccent, Icons.check);
        _auth.signOut();
        Navigator.popAndPushNamed(context, LoginScreen.id);
        //Navigator.pushNamed(context, LoginScreen.id);
      },color: Colors.lightBlueAccent, text: 'logout')),
    );
  }
}