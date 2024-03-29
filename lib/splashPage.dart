import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'moodHome.dart';
import 'globalState.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool success = true;
  bool neverSignedIn = false;

  @override
  initState() {
    User currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      debugPrint("not null");
      setState(() {
        neverSignedIn = false;
      });
      globalState.setUser(currentUser).then((glsuccess) {
        debugPrint("setuserstate: " + glsuccess.toString());
        if (glsuccess) {
          FirebaseFirestore.instance
              .collection("users")
              .doc(currentUser.uid)
              .get()
              .then((DocumentSnapshot result) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => MoodHome(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                        )));
            success = true;
          }).catchError((err) => setState(() {
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
    } else {
      neverSignedIn = true;
      setState(() {
        neverSignedIn = true;
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (neverSignedIn) {
      return Scaffold(
        /*
      appBar: AppBar(
        title: Text('Search demo'),
      ),*/

        body: Container(
          child: Column(
            children: [
              Spacer(flex: 1),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: <Widget>[
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: Image.asset("images/philosopher.png",
                            height: MediaQuery.of(context).size.height * 0.5)),
                    Align(
                      //top: MediaQuery.of(context).size.height * 0.5 * 0.6,
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          Spacer(flex: 1),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              "Mood dex is a place where you store moods you experienced, rate them and share them with others.\n\n" +
                                  "Click 'Get started' to instantly create an anonymous account.\n\nRegister properly later in the profile section.",
                            ),
                          ),
                          Spacer(flex: 3),
                        ],
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.9,
                      left: MediaQuery.of(context).size.width * 0.5,
                      child: CupertinoButton(
                          child: Text("Get Started"),
                          onPressed: () async {
                            //create an anonymous user
                            debugPrint("ok user");
                            FirebaseAuth.instance.signInAnonymously().then(
                                (UserCredential res) => globalState
                                        .registerUser(res.user, "anonymous", "")
                                        .then((val) {
                                      debugPrint("registered user");
                                      globalState.setUser(res.user).then((val) {
                                        debugPrint("set user");
                                        FirebaseFirestore.instance
                                            .collection("users")
                                            .doc(res.user.uid)
                                            .get()
                                            .then((DocumentSnapshot result) {
                                          debugPrint("final get request");
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MoodHome(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        height: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .height,
                                                      )));
                                        }).catchError((err) => setState(() {
                                                  success = false;
                                                }));
                                      });
                                    }));
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      debugPrint("Heyo building");
      return Scaffold(
        body: Stack(
          children: <Widget>[
            Align(
                alignment: Alignment.topRight,
                child: Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Image.asset("images/gondola.png",
                        width: MediaQuery.of(context).size.width * 1))),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Text("Connecting to the server...",
                      style: TextStyle(fontSize: 14, color: Colors.grey))),
            ),
          ],
        ),
      );
    }
  }
}
