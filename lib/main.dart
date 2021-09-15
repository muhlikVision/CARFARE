import 'package:carfare/screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(CarFare());
}


class CarFare extends StatefulWidget {
  @override
  _CarFareState createState() =>_CarFareState();
}

class _CarFareState extends State<CarFare>{

  String currentPage = LoginScreen.id;
  LoginScreen log = LoginScreen();

  @override
  void initState() {

    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async{
    String token = await log.getToken();
    print('MAIN DART TOKEN: $token');
    if(token != null){
      print('IN CONDITION');
      setState(() {
        currentPage = HomeScreen.id;
      });
    }
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