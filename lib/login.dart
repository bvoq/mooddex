import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'moodHome.dart';
import 'register.dart';
import 'globalState.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  TextEditingController emailInputController;
  TextEditingController pwdInputController;
  Text errorMessage = Text("");

  @override
  initState() {
    emailInputController = new TextEditingController();
    pwdInputController = new TextEditingController();
    super.initState();
  }

  String emailValidator(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Email format is invalid';
    } else {
      return null;
    }
  }

  String pwdValidator(String value) {
    if (value.length < 8) {
      return 'Password must be longer than 8 characters';
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: Container(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
                child: Form(
              key: _loginFormKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    autocorrect: false,
                    decoration: InputDecoration(
                        labelText: 'Email*',
                        hintText: "johnthebeast@gmail.com"),
                    controller: emailInputController,
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValidator,
                  ),
                  TextFormField(
                    autocorrect: false,
                    decoration: InputDecoration(
                        labelText: 'Password*', hintText: "********"),
                    controller: pwdInputController,
                    obscureText: true,
                    validator: pwdValidator,
                  ),
                  RaisedButton(
                    child: Text("Login"),
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    onPressed: () async {
                      if (_loginFormKey.currentState.validate()) {
                        try {
                          AuthResult authRes = await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                                  email: emailInputController.text,
                                  password: pwdInputController.text)
                              .catchError((err) {
                            String errorStr = "";
                            switch (err.code) {
                              case "ERROR_INVALID_EMAIL":
                                errorStr =
                                    "Your email address appears to be malformed.";
                                break;
                              case "ERROR_WRONG_PASSWORD":
                                errorStr = "Your password is wrong.";
                                break;
                              case "ERROR_USER_NOT_FOUND":
                                errorStr =
                                    "User with this email doesn't exist.";
                                break;
                              case "ERROR_USER_DISABLED":
                                errorStr =
                                    "User with this email has been disabled.";
                                break;
                              case "ERROR_TOO_MANY_REQUESTS":
                                errorStr =
                                    "Too many requests. Try again later.";
                                break;
                              case "ERROR_OPERATION_NOT_ALLOWED":
                                errorStr =
                                    "Signing in with Email and Password is not enabled.";
                                break;
                              default:
                                errorStr = "An undefined Error happened.";
                                debugPrint("The error message is: " + errorStr);

                                errorMessage = Text(errorStr);
                                setState(() => {});
                              //return;
                            }
                          });
                          if (authRes != null) {
                            //FirebaseUser currentUser =
                            //    await _auth.currentUser();

                            //DocumentSnapshot result = await Firestore.instance
                            //    .collection("users")
                            //    .document(authRes.user.uid)
                            //    .get();
                            FirebaseUser u =
                                await FirebaseAuth.instance.currentUser();
                            await globalState.setUser(u);
                            debugPrint("Hopefully not null: " + u.email);
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MoodHome()));
                            //.catchError((err) => debugPrint(err)))
                          } else {
                            errorMessage = Text("Login failed.",
                                style: TextStyle(color: Colors.red));
                            setState(() => {});
                          }
                        } catch (error) {
                          debugPrint("OK OK OK " + error.toString());
                          /*
                          String errorStr = "";
                          switch (error) {
                            case "ERROR_INVALID_EMAIL":
                              errorStr =
                                  "Your email address appears to be malformed.";
                              break;
                            case "ERROR_WRONG_PASSWORD":
                              errorStr = "Your password is wrong.";
                              break;
                            case "ERROR_USER_NOT_FOUND":
                              errorStr = "User with this email doesn't exist.";
                              break;
                            case "ERROR_USER_DISABLED":
                              errorStr =
                                  "User with this email has been disabled.";
                              break;
                            case "ERROR_TOO_MANY_REQUESTS":
                              errorStr = "Too many requests. Try again later.";
                              break;
                            case "ERROR_OPERATION_NOT_ALLOWED":
                              errorStr =
                                  "Signing in with Email and Password is not enabled.";
                              break;
                            default:
                              errorStr = "An undefined Error happened.";
                              debugPrint("The error message is: " + errorStr);

                              errorMessage = Text(errorStr);
                              setState(() => {});
                          }
                          */
                        }
                      }
                    },
                  ),
                  Text("Don't have an account yet?"),
                  FlatButton(
                    child: Text("Create a new account"),
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterPage()));
                    },
                  ),
                  errorMessage,
                ],
              ),
            ))));
  }
}
