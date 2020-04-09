import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'moodSearch.dart';
import 'record.dart';

class MoodHome extends StatefulWidget {
  @override
  MoodState createState() => MoodState();
}

class MoodState extends State<MoodHome> {
  @override
  Widget build(BuildContext context) {
    //iphone: 414.0 x 896.0
    //ipad pro: 1024.0 x 1366.0
    debugPrint('The size of this device is: ' +
        MediaQuery.of(context).size.width.toString() +
        " x " +
        MediaQuery.of(context).size.height.toString());
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
