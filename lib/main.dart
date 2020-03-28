// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// When editing use Cmd+Shift+P => Dart: Use Recommended Settings
// flutter clean

// I am leaving my job, here's my two weeks notice.
// I get my work done better remotely and here's why.
// Could we negotiate in the future about working remotely.

//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'moodSearch.dart';

void main() => runApp(MyApp());

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
          return MoodHome();
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
          //primaryColor: Color(0x003c7e00),
          accentColor: Colors.deepOrange),
      */
      debugShowCheckedModeBanner: true,
    );
  }
}

class MoodHome extends StatefulWidget {
  @override
  MoodState createState() => MoodState();
}

class MoodState extends State<MoodHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      appBar: AppBar(
        title: Text('Search demo'),
      ),*/
      body: Center(
        child: Builder(
          builder: (context) => MaterialButton(
            //MaterialButton
            child: Text('Search'),
            /*
            onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => MoodSearchCupertino())),
            */

            onPressed: () => showSearch(
              context: context,
              delegate: MoodSearchMaterial(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () => showSearch(
          context: context,
          delegate: MoodSearchMaterial(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        //color: Colors.orange,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.art_track), title: Text('My Moods')),
          BottomNavigationBarItem(
              icon: Icon(Icons.supervisor_account), title: Text('Friends')),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
