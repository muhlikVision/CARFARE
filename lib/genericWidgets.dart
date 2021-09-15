import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/painting.dart';

final _firestore = FirebaseFirestore.instance; //send and get data

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
            text,
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  InputField({this.onChange, this.text, this.bcolor, this.chk, this.type});
  final Function onChange;
  final String text;
  final Color bcolor;
  final bool chk;
  final TextInputType type;

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

  @override
  Widget build(BuildContext context) {
    //
    return TextField(
      keyboardType: checkText(type),
      obscureText: checkNull(chk),
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.yellowAccent),
      onChanged: onChange,
      decoration: InputDecoration(
        hintText: text,
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32.0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: bcolor, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(32.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: bcolor, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(32.0)),
        ),
      ),
    );
  }
}