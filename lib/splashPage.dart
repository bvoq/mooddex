import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'moodHome.dart';
import 'globalState.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  initState() {
    FirebaseAuth.instance.currentUser().then((currentUser) {
      if (currentUser == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        globalState.setUser(currentUser);
        Firestore.instance
            .collection("users")
            .document(currentUser.uid)
            .get()
            .then((DocumentSnapshot result) => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MoodHome())))
            .catchError((err) => debugPrint(err));
      }
    }).catchError((err) => debugPrint(err));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Text("Loading..."),
        ),
      ),
    );
  }
}
