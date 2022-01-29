// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// When editing use Cmd+Shift+P => Dart: Use Recommended Settings
// flutter clean

// For adding Google OAuth: https://developers.google.com/identity/sign-in/ios/start-integrating?authuser=2

//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';

import 'splashPage.dart';

void main() async {
  //Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //final wordPair = WordPair.random();

    return MaterialApp(
      title: 'Mooddex',
      //home: RandomWords(),

      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) {
          return SplashPage();
        },
      },
      /*
      onUnknownRoute: (RouteSettings setting) {
        // To can ask the RouterSettings for unknown router name.
        // String unknownRoute = setting.name;
        debugPrint('Trying to access ' + setting.name);
        assert(false);
        return new MaterialPageRoute(
            builder: (context) => Text("Page " + setting.name + " not found"));
      },*/
      /*
      theme: ThemeData(
          primaryColor: Colors.deepOrangeAccent,
          brightness: Brightness.light,
          backgroundColor: Colors.orange[100],
          //primaryColor: Color(0x003c7e00),
          accentColor: Colors.deepOrange),
      */
      debugShowCheckedModeBanner: false,
    );
  }
}
