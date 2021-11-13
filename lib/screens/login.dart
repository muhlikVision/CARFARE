import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'guard_home.dart';
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
  final _firestore = FirebaseFirestore.instance; //send and get data
  final storage = new FlutterSecureStorage();

  MobileVerificationState currentState =
      MobileVerificationState.SHOW_MOBILE_FORM_STATE;

//vars
  String verificationID;
  String email, password, phone, otp;
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

  int chkEmailSyntax(String email) {
    try {
      String temp = '@ucp.edu.pk';
      String guard = '@ucp.guard.pk';
      int n = email.length - 11;
      int g = email.length - 13;
      if (temp == email.substring(n)) {
        return 1;
      } else if(guard == email.substring(g)) {
        return 2;
      }
      else
        {
          return 0;
        }
    } catch (e) {
      showToast('Invalid Email Syntax', Colors.redAccent, Icons.clear);
      return 0;
    }
  }

  void signInWithPhone(PhoneAuthCredential phoneAuthCredential) async {
    setState(() {
      showSpinner = true;
    });
    try {
      final chkAuth = await _auth.signInWithCredential(phoneAuthCredential);

      if (chkAuth.user != null) {
        Navigator.pushNamed(context, HomeScreen.id);
        setState(() {
          showSpinner = false;
        });
      }
      setState(() {
        showSpinner = false;
      });
    } on FirebaseAuthException catch (e) {
      print(e);
      showToast(e.message, Colors.redAccent, Icons.clear);
      setState(() {
        showSpinner = false;
      });
    }
  }

  loginPage(context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
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
                  if (chkEmailSyntax(email) == 1 &&
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
                        Navigator.pushNamed(context, HomeScreen.id);
                        msgTextCont.clear();
                      }
                    } on FirebaseAuthException catch (e) {
                      showToast(e.message, Colors.redAccent, Icons.clear);
                      setState(() {
                        showSpinner = false;
                      });
                    }
                    setState(() {
                      showSpinner = false;
                    });
                  } else if (chkEmailSyntax(email) == 2 &&
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
                        // SharedPreferences pref =
                        // await SharedPreferences.getInstance();
                        // pref.setString('email', email);
                        Navigator.pushNamed(context, GuardScreen.id);
                        msgTextCont.clear();
                      }
                    } on FirebaseAuthException catch (e) {
                      showToast(e.message, Colors.redAccent, Icons.clear);
                      setState(() {
                        showSpinner = false;
                      });
                    }
                    setState(() {
                      showSpinner = false;
                    });
                  }
                  else {
                    showToast(
                        'Invalid Email Syntax', Colors.redAccent, Icons.clear);
                  }
                  msgTextCont.clear();
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
                phone = value;
              },
              bcolor: Colors.deepOrange,
              text: 'Enter Phone Number',
              tec: phoneController,
              type: TextInputType.phone,
            ),
            SizedBox(
              height: 24.0,
            ),
            ButtonBuilder(
                onPress: () async {
                  if (phone != null && phone.length >= 13) {
                    setState(() {
                      showSpinner = true;
                    });
                    _auth.verifyPhoneNumber(
                        phoneNumber: phone,
                        verificationCompleted: (phoneAuthCredential) async {
                          setState(() {
                            showSpinner = false;
                          });
                          //signInWithPhone(phoneAuthCredential);
                        },
                        verificationFailed: (verificationFailed) async {
                          showToast(verificationFailed.message,
                              Colors.redAccent, Icons.clear);
                          setState(() {
                            showSpinner = false;
                          });
                        },
                        codeSent: (verificationId, resendingToken) async {
                          setState(() {
                            showSpinner = false;
                            currentState =
                                MobileVerificationState.SHOW_OTP_FORM_STATE;
                            phoneController.clear();
                            phone = null;
                            this.verificationID = verificationId;
                          });
                        },
                        codeAutoRetrievalTimeout: (verificationId) async {});
                  } else {
                    showToast(
                        'Invalid Phone Syntax', Colors.redAccent, Icons.clear);
                  }
                },
                color: Colors.blue,
                text: 'VERIFY'),
          ],
        ),
      ),
    );
  }

  otpPage(context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RoundButtonBuilder(
                  splashcolor: Colors.redAccent,
                  sizeConstraints: 45,
                  customButtonIcon: Icons.arrow_back,
                  onPress: () {
                    setState(() {
                      currentState =
                          MobileVerificationState.SHOW_MOBILE_FORM_STATE;
                    });
                    otpController.clear();
                  },
                ),
              ],
            ),
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
                otp = value;
              },
              bcolor: Colors.deepOrange,
              text: 'Enter OTP',
              type: TextInputType.number,
              tec: otpController,
            ),
            SizedBox(
              height: 48.0,
            ),
            ButtonBuilder(
                onPress: () async {
                  if (otp != null && otp.length >= 6) {
                    PhoneAuthCredential phoneAuthCredential =
                        PhoneAuthProvider.credential(
                            verificationId: verificationID, smsCode: otp);
                    signInWithPhone(phoneAuthCredential);
                  } else {
                    showToast('Invalid OTP', Colors.redAccent, Icons.clear);
                    otpController.clear();
                  }
                },
                color: Colors.blue,
                text: 'VERIFY'),
            SizedBox(
              height: 5.0,
            ),
          ],
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return;
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: true,
        backgroundColor: Color(0xFF141313),
        body: currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
            ? loginPage(context)
            : otpPage(context),
      ),
    );
  }
}
