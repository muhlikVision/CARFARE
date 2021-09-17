import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../genericWidgets.dart';
import 'home.dart';

enum MobileVerificationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE,
} //for mobile verification

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final storage = new FlutterSecureStorage();

  MobileVerificationState currentState =
      MobileVerificationState.SHOW_MOBILE_FORM_STATE;

//vars
  String email, password;
  bool showSpinner = false;
  final msgTextCont = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  bool chkEmailSyntax(String email) {
    try {
      String temp = '@ucp.edu.pk';
      int n = email.length - 11;
      if (temp == email.substring(n)) {
        return true;
      } else
        return false;
    } catch (e) {
      showToast('Invalid Email Syntax', Colors.redAccent, Icons.clear);
      return false;
    }
  }

  loginPage(context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      color: Colors.blue,
      child: Padding(
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
                  child: Image.asset('images/logo.jpg'),
                ),
              ),
            ),
            SizedBox(
              height: 48.0,
            ),
            InputField(
              onChange: (value) {
                email = value;
              },
              bcolor: Colors.deepOrange,
              text: 'Enter Email',
              type: TextInputType.emailAddress,
            ),
            SizedBox(
              height: 8.0,
            ),
            InputField(
                onChange: (value) {
                  password = value;
                },
                bcolor: Colors.deepOrange,
                text: 'Enter Password',
                chk: true),
            SizedBox(
              height: 24.0,
            ),
            ButtonBuilder(
                onPress: () async {
                  if (chkEmailSyntax(email) == true &&
                      email != null &&
                      password != null) {
                    setState(() {
                      showSpinner = true;
                    });
                    try {
                      final user = await _auth.signInWithEmailAndPassword(
                          email: email, password: password);
                      if (user != null) {
                        //storeTokenAndData(user);
                        print(user);
                        SharedPreferences pref =
                            await SharedPreferences.getInstance();
                        pref.setString('email', email);
                        showToast(
                            'LOGGED IN', Colors.lightGreenAccent, Icons.check);
                        Navigator.pushNamed(context, HomeScreen.id);
                      }
                    } catch (e) {
                      print(e);
                      showToast(e, Colors.redAccent, Icons.clear);
                    }
                    setState(() {
                      showSpinner = false;
                    });
                    msgTextCont.clear();
                  } else {
                    showToast(
                        'Invalid Email Syntax', Colors.redAccent, Icons.clear);
                  }
                },
                color: Colors.green,
                text: 'LOGIN'),
            SizedBox(
              height: 24.0,
            ),
            Center(
                child: Text(
              '            Forgot Credentials?\nEnter PhoneNo for OTP Verification',
              style: TextStyle(color: Colors.white),
            )),
            SizedBox(
              height: 24.0,
            ),
            InputField(
              onChange: (value) {
                password = value;
              },
              bcolor: Colors.deepOrange,
              text: 'Enter Phone Number',
              tec: phoneController,
            ),
            SizedBox(
              height: 24.0,
            ),
            ButtonBuilder(onPress: () {}, color: Colors.blue, text: 'VERIFY'),
          ],
        ),
      ),
    );
  }

  otpPage(context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      color: Colors.blue,
      child: Padding(
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
                  child: Image.asset('images/logo.jpg'),
                ),
              ),
            ),
            SizedBox(
              height: 48.0,
            ),
            InputField(
              onChange: (value) {
                email = value;
              },
              bcolor: Colors.deepOrange,
              text: 'Enter OTP',
              type: TextInputType.number,
              tec: otpController,
            ),
            SizedBox(
              height: 48.0,
            ),
            ButtonBuilder(onPress: () {
              setState(() {
                currentState = MobileVerificationState.SHOW_OTP_FORM_STATE;
              });
            }, color: Colors.blue, text: 'VERIFY'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF141313),
        body: currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
            ? loginPage(context)
            : otpPage(context));
  }
}
