import 'dart:math';
import 'dart:ui';

import 'package:carfare/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/painting.dart';
import 'screens/guard_home.dart';


final _firestore = FirebaseFirestore.instance; //send and get data


class RoundButtonBuilder extends StatelessWidget {
  final Color splashcolor;
  final double sizeConstraints;
  final IconData customButtonIcon;
  final Function() onPress;

  RoundButtonBuilder(
      {@required this.splashcolor,
        @required this.sizeConstraints,
        @required this.customButtonIcon,
        @required this.onPress});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: onPress,
      shape: CircleBorder(),
      fillColor: Colors.grey,
      elevation: 20.0,
      constraints: BoxConstraints.tightFor(
        width: sizeConstraints,
        height: sizeConstraints,
      ),
      splashColor: splashcolor,
      child: Icon(
        customButtonIcon,
        size: 28,
        color: Colors.white,
      ),
    );
  }
}
class MsgBubble extends StatelessWidget {
  final String msgText, msgSender, msgTime;
  final bool isMe;

  MsgBubble(this.msgText, this.msgSender, this.msgTime, this.isMe);

  @override
  Widget build(BuildContext context) {
    if(isMe == false){
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$msgSender',
              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
            ),
            SizedBox(
              height: 8,
            ),
            Material(
              elevation: 5,
              borderRadius: BorderRadiusDirectional.only(
                  bottomEnd: Radius.circular(20),
                  bottomStart: Radius.circular(20),
                  topEnd: Radius.circular(20)),
              color: Colors.lightBlueAccent,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  ' $msgText ',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              '$msgTime',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent),
            ),
          ],
        ),
      );
    }
    else
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '$msgSender',
              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
            ),
            SizedBox(
              height: 8,
            ),
            Material(
              elevation: 5,
              borderRadius: BorderRadiusDirectional.only(
                  bottomEnd: Radius.circular(20),
                  topStart: Radius.circular(20),
                  bottomStart: Radius.circular(20)),
              color: Colors.limeAccent,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  ' $msgText ',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              '$msgTime',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent),
            ),
          ],
        ),
      );
  }
}
class ButtonBuilder extends StatelessWidget {
  ButtonBuilder({this.color, @required this.onPress, this.text});
  final Color color;
  final Function onPress;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: color,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: onPress,
          minWidth: 200.0,
          height: 42.0,
          child: Text(
            text, style: TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }
}
class InputField extends StatelessWidget {
  InputField({this.onChange, this.text, this.bcolor, this.chk, this.type, this.tec});
  final Function onChange;
  final String text;
  final Color bcolor;
  final bool chk;
  final TextInputType type;
  final TextEditingController tec;
  
  bool checkNull(bool chk) {
    if (chk == null)
      return false;
    else
      return true;
  }

  TextInputType checkText(TextInputType text) {
    if (text == null)
      return TextInputType.text;
    else
      return type;
  }
  TextEditingController checkTec(TextEditingController text) {
    if (text == null)
      return TextEditingController();
    else
      return tec;
  }
  
  @override
  Widget build(BuildContext context) {
    //
    return TextField(
      controller: checkTec(tec),
      keyboardType: checkText(type),
      obscureText: checkNull(chk),
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white),
      onChanged: onChange,
      decoration: InputDecoration(
        hintText: text,
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: bcolor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: bcolor, width: 4.0),
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
      ),
    );
  }
}
class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('timeAt').snapshots(),
      builder: (context, snapshot) {
        List<MsgBubble> messageBox = [];
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.limeAccent,
            ),
          );
        }
        final msgs = snapshot.data.docs.reversed;

        for (var i in msgs) {
          if (i.data() != null) {
            var data = i.data() as Map<String, dynamic>;
            final msgText = data['texts'];
            final msgSender = data['sender'];
            final msgTime = data['timeAt'];

            var loggedinUser;
            final currentUser = loggedinUser.email; //checking if sender is the logged in user to manipulate bubble

            final msgBox = MsgBubble(msgText, msgSender, msgTime, currentUser == msgSender);
            messageBox.add(msgBox);
            //print(messageBox);
          }
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageBox,
          ),
        );
      },
    );
  }
}

class CustomTile extends StatelessWidget{

  final carName;
  final type;
  final status;
  final verify;
  final numberPlate;


  const CustomTile({Key key, this.carName, this.type, this.status, this.verify, this.numberPlate}) : super(key: key);

  chkStatus(status){
    if(status == false)
      {
        return Icons.cancel;
      }
    else
      {
        return Icons.check;
      }
  }
  chkVerify(verify){
    if(verify == false)
    {
      return Icons.cancel;
    }
    else
    {
      return Icons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        hoverColor: Colors.black54,
        tileColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: new BoxDecoration(
                border: new Border(
                    right: new BorderSide(width: 1.0, color: Colors.white24))),
            child: Icon(type == 'car'? Icons.airport_shuttle: Icons.two_wheeler, color: Colors.white),
          ),
          title: Text(
            '$carName | $numberPlate',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

          subtitle: Column(
            children: [
              Row(
                children: <Widget>[
                  Icon(chkStatus(status), color: chkStatus(status) == Icons.check? Colors.greenAccent:Colors.redAccent),
                  Text(" Active Status", style: TextStyle(color: Colors.white))
                ],
              ),
              Row(
                children: <Widget>[
                  Icon(chkVerify(verify), color: chkVerify(verify) == Icons.check? Colors.greenAccent:Colors.redAccent),
                  Text(" Traffic Police Verification Status", style: TextStyle(color: Colors.white))
                ],
              ),
            ],
          ),
          trailing:
          Icon(Icons.keyboard_arrow_right, color: Colors.blueAccent, size: 30.0)),
    );
  }
}

class CustomFloorTile extends StatelessWidget{

  final floorName;
  final count;
  final Function callBackState;
  const CustomFloorTile({Key key, this.count, this.floorName, this.callBackState}) : super(key: key);


  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
          hoverColor: Colors.black54,
          tileColor: Colors.white30,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          // leading: Container(
          //   padding: EdgeInsets.only(right: 12.0),
          //   decoration: new BoxDecoration(
          //       border: new Border(
          //           right: new BorderSide(width: 1.0, color: Colors.white24))),
          //   child: Icon(floorName == 'car'? Icons.airport_shuttle: Icons.two_wheeler, color: Colors.white),
          // ),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("$floorName", style: TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RoundButtonBuilder(splashcolor: Colors.red, sizeConstraints: 40, customButtonIcon: Icons.remove, onPress: (){
                    callBackState(true, floorName, count - 1);
                    //print('$floorName $count');
                  }),
                  Text(
                    ' $count ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  RoundButtonBuilder(splashcolor: Colors.greenAccent, sizeConstraints: 40, customButtonIcon: Icons.add, onPress: (){
                    callBackState(true, floorName, count + 1);
                  }),
                ],
              ),

            ],
          ),
          // subtitle: Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   children: [
          //     Text("Intermediate", style: TextStyle(color: Colors.white)),
          //   ],
          // ),

          // subtitle: Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   crossAxisAlignment: CrossAxisAlignment.stretch,
          //   children: [
          //     Center(
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: [
          //           Text("$floorName", style: TextStyle(color: Colors.white)),
          //         ],
          //       ),
          //     ),
          //
          //   ],
          // ),
         ),
    );
  }
}

class CustomFloorDisplayTile extends StatelessWidget{

  final floorName;
  final reserve;
  final count;

  const CustomFloorDisplayTile({Key key, this.count, this.floorName, this.reserve}) : super(key: key);


  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        hoverColor: Colors.black54,
        tileColor: Colors.white10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        // leading: Container(
        //   padding: EdgeInsets.only(right: 12.0),
        //   decoration: new BoxDecoration(
        //       border: new Border(
        //           right: new BorderSide(width: 1.0, color: Colors.white24))),
        //   child: Icon(floorName == 'car'? Icons.airport_shuttle: Icons.two_wheeler, color: Colors.white),
        // ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("$floorName", style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  ' $count ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Reserved  |", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,)),
                Text("  $reserve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomReserveTile extends StatelessWidget{

  final floorName;
  final userName;
  final startTime;
  final endTime;
  final numberPlate;

  const CustomReserveTile({Key key, this.floorName, this.userName, this.startTime, this.endTime, this.numberPlate}) : super(key: key);


  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        hoverColor: Colors.black54,
        tileColor: DateTime.parse(endTime).isBefore(DateTime.now())? Colors.red: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: new BoxDecoration(
                border: new Border(
                    right: new BorderSide(width: 1.0, color: Colors.white24))),
            child: Icon(Icons.airport_shuttle),
          ),
          title: Text(
            '$numberPlate',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

          subtitle: Column(
            children: [
              Row(
                children: <Widget>[
                  Icon(Icons.access_alarm),
                  Text(" Start | $startTime", style: TextStyle(color: Colors.white))
                ],
              ),
              Row(
                children: <Widget>[
                  Icon(Icons.alarm_off),
                  Text(" End | $endTime", style: TextStyle(color: Colors.white))
                ],
              ),
              Row(
                children: <Widget>[
                  Icon(Icons.add_business_sharp),
                  Text(" Parking Floor | $floorName", style: TextStyle(color: Colors.white))
                ],
              ),
            ],
          ),
          trailing:
          Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0)),

    );
  }
}