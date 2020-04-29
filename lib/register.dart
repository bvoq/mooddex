import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'globalState.dart';
import 'moodHome.dart';
import 'stopwords.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({Key key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  TextEditingController userNameInputController;
  TextEditingController emailInputController;
  TextEditingController pwdInputController;
  TextEditingController confirmPwdInputController;

  @override
  initState() {
    userNameInputController = new TextEditingController();
    emailInputController = new TextEditingController();
    pwdInputController = new TextEditingController();
    confirmPwdInputController = new TextEditingController();
    super.initState();
  }

  String userNameValidator(String value) {
    if (value.length < 4) {
      return "Please enter a username of more than 3 characters.";
    } else if (blacklistUsernames.contains(value)) {
      return "This username is not available.";
    }
    return null;
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
    } else if (pwdInputController.text != confirmPwdInputController.text) {
      return 'Passwords do not match!';
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(globalState.user.isAnonymous
              ? "Register and link account"
              : "Create a new account"),
        ),
        body: Container(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
                child: Form(
              key: _registerFormKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    autocorrect: false,
                    decoration: InputDecoration(
                        labelText: 'Username* (will be public)',
                        hintText: "beast"),
                    controller: userNameInputController,
                    validator: userNameValidator,
                    maxLength: 32,
                  ),
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
                  TextFormField(
                    autocorrect: false,
                    decoration: InputDecoration(
                        labelText: 'Confirm Password*', hintText: "********"),
                    controller: confirmPwdInputController,
                    obscureText: true,
                    validator: pwdValidator,
                  ),
                  RaisedButton(
                    child: Text("Register"),
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    onPressed: () {
                      debugPrint("try registering");
                      if (_registerFormKey.currentState.validate()) {
                        debugPrint("validated locally");

                        try {
                          if (globalState.user.isAnonymous) {
                            AuthCredential credential =
                                EmailAuthProvider.getCredential(
                                    email: emailInputController.text,
                                    password: pwdInputController.text);

                            globalState.user
                                .linkWithCredential(credential)
                                .then((authres) {
                              debugPrint("authorized till here");
                              globalState
                                  .registerUser(
                                      authres.user,
                                      userNameInputController.text,
                                      emailInputController.text)
                                  .then((vo) {
                                debugPrint("registered user");
                                globalState.setUser(authres.user).then((vo) {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MoodHome()),
                                      (_) => false);
                                  userNameInputController.clear();
                                  emailInputController.clear();
                                  pwdInputController.clear();
                                  confirmPwdInputController.clear();
                                });
                              });
                            });
                          } else {
                            FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                    email: emailInputController.text,
                                    password: pwdInputController.text)
                                .catchError((error) => debugPrint(
                                    "create user error: " + error.toString()))
                                .then((authres) {
                              debugPrint("authorized user here");
                              globalState
                                  .registerUser(
                                      authres.user,
                                      userNameInputController.text,
                                      emailInputController.text)
                                  .then((result) {
                                debugPrint("registered user here");
                                globalState.setUser(authres.user).then((vo) {
                                  debugPrint("set user till here");
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MoodHome()),
                                      (_) => false);
                                  userNameInputController.clear();
                                  emailInputController.clear();
                                  pwdInputController.clear();
                                  confirmPwdInputController.clear();
                                });
                              });
                            });
                          }
                        } catch (error) {
                          debugPrint("register error: " + error.toString());
                        }

/*  *async message for no internet connection*
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          //connected ok
        }
      } on SocketException catch (_) {
        return "No internet connection available.";
      }
*/
                        /*else {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Error"),
                                  content: Text("The passwords do not match"),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text("Close"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                );
                              });
                        }*/
                      }
                    },
                  ),
                  Text("Already have an account?"),
                  FlatButton(
                    child: Text("Login here!"),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                ],
              ),
            ))));
  }
}
