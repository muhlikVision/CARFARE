import 'package:carfare/screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

String currentPage = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SharedPreferences pref = await SharedPreferences.getInstance();

  var email = pref.getString('email');
  print(email);
  if(email != null) {
    currentPage = HomeScreen.id;
    runApp(CarFare());
  }
  else {
    currentPage = LoginScreen.id;
    runApp(CarFare());
  }
}


class CarFare extends StatefulWidget {
  @override
  _CarFareState createState() =>_CarFareState();
}

class _CarFareState extends State<CarFare>{

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: TextTheme(
          body1: TextStyle(color: Colors.black54),
        ),
      ),

      initialRoute: currentPage,
      routes: {
        LoginScreen.id: (context) => LoginScreen(),
        HomeScreen.id: (context) => HomeScreen(),
      },

    );
  }

}