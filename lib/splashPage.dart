import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'moodHome.dart';
import 'globalState.dart';
import 'dynamicLinks.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool success = true;

  @override
  initState() {
    FirebaseAuth.instance.currentUser().then((currentUser) {
      if (currentUser == null) {
        //create an anonymous user instead
        FirebaseAuth.instance.signInAnonymously().then((AuthResult res) =>
            globalState
                .registerUser(res.user, "anonymous", "")
                .then((val) => globalState.setUser(res.user).then((val) {
                      Firestore.instance
                          .collection("users")
                          .document(res.user.uid)
                          .get()
                          .then((DocumentSnapshot result) =>
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MoodHome())))
                          .catchError((err) => setState(() {
                                success = false;
                              }));
                    })));
      } else {
        globalState.setUser(currentUser).then((success) {
          if (success) {
            Firestore.instance
                .collection("users")
                .document(currentUser.uid)
                .get()
                .then((DocumentSnapshot result) => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MoodHome())))
                .catchError((err) => setState(() {
                      success = false;
                    }));
          } else {
            setState(() {
              success = false;
            });
          }
        }).catchError((error) {
          setState(() {
            success = false;
          });
        });
      }
    }).catchError((err) {
      setState(() {
        success = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: success
              ? Text("Loading...")
              : Text("Failed connecting to the server.",
                  style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
