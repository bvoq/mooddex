import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
//import 'package:universal_html/html.dart';

import 'moodList.dart';
import 'moodReport.dart';
import 'moodSwipe.dart';
import 'globalState.dart';
import 'login.dart';
import 'register.dart';
import 'dynamicLinks.dart';

import 'package:url_launcher/url_launcher.dart';

class MoodHome extends StatefulWidget {
  double width, height;
  MoodHome({Key key, @required this.width, @required this.height})
      : super(key: key);
  @override
  MoodHomeState createState() => MoodHomeState(width, height);
}

class MoodHomeState extends State<MoodHome> {
  int bottomNavigationIndex;
  MyMoods myMoods;
  MoodTypes moodTypes;
  MoodSwipe moodSwipe;

  MoodHomeState(double width, double height) {
    bottomNavigationIndex = 0;
    myMoods = MyMoods();
    moodTypes = MoodTypes();
    moodSwipe = MoodSwipe(width: width, height: height);
  }
  @override
  void initState() {
    super.initState();
    initDynamicLinks(context);
  }

  @override
  Widget build(BuildContext context) {
    //iphone: 414.0 x 896.0
    //ipad pro: 1024.0 x 1366.0
    debugPrint('The size of this device is: ' +
        MediaQuery.of(context).size.width.toString() +
        " x " +
        MediaQuery.of(context).size.height.toString());
/*
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.art_track),
            title: Text('My Moods'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add),
            title: Text('Add moods'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_solid),
            title: Text('Friends'),
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text('Page 1 of tab $index'),
              ),
              child: Center(
                child: CupertinoButton(
                  child: const Text('Next page'),
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (BuildContext context) {
                          return CupertinoPageScaffold(
                            navigationBar: CupertinoNavigationBar(
                              middle: Text('Page 2 of tab $index'),
                            ),
                            child: Center(
                              child: CupertinoButton(
                                child: const Text('Back'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
    */

    return Scaffold(
      /*
      appBar: AppBar(
        title: Text('Search demo'),
      ),*/

      body: bottomNavigationIndex == 0
          ? moodTypes
          /*CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(largeTitle: Text("Mood Dex")),
                myMoods,
              ],
            )*/
          : bottomNavigationIndex == 1
              ? moodSwipe
              : bottomNavigationIndex == 2
                  ? Container(
                      child: Column(
                        children: [
                          CupertinoNavigationBar(middle: Text("My Profile")),
                          Spacer(flex: 1),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text("Username: " + globalState.userName)),
                          globalState.user.isAnonymous
                              ? Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 48),
                                  child: Text("Anonymous user. " +
                                      globalState.user.isAnonymous.toString()))
                              : Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 48),
                                  child: Text("Email: " +
                                      globalState.user.email +
                                      (globalState.user.emailVerified
                                          ? " (verified)"
                                          : " (unverified)"))),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                  "UID: " + globalState.user.uid.toString())),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text("Photo: " +
                                  globalState.user.photoURL.toString())),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text("Provider: " +
                                  globalState.user.providerData.toString())),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text("Phone number: " +
                                  globalState.user.phoneNumber)),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text("RefreshToken: " +
                                  globalState.user.refreshToken.toString())),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text("Metadata: " +
                                  globalState.user.metadata.toString())),
                          Spacer(flex: 6),
                          globalState.user.isAnonymous
                              ? Center(
                                  child: RaisedButton(
                                    child: Text(
                                        "Register and link anonymous account"),
                                    color: Theme.of(context).primaryColor,
                                    textColor: Colors.white,
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RegisterPage(),
                                          ));
                                    },
                                  ),
                                )
                              : Spacer(flex: 1),
                          Center(
                            child: RaisedButton(
                                child: Text("Login with a different account"),
                                color: Theme.of(context).primaryColor,
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginPage(),
                                      ));
                                }),
                          ),
                          Spacer(flex: 1),
                          CupertinoButton(
                              child: Text("About page"),
                              onPressed: () {
                                launch("https://mood-dex.com/about");
                              }),
                          Spacer(flex: 1),
                          CupertinoButton(
                              child: Text("Give feedback"),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) => MoodReport(
                                        reportType: "feedback",
                                        reportLocation: "other_" +
                                            (new DateTime.now())
                                                .millisecondsSinceEpoch
                                                .toString() +
                                            "_" +
                                            globalState.getUser().uid,
                                        reportDescription:
                                            "Please type your feedback here.\n"));
                              }),
                          Spacer(flex: 2),
                        ],
                      ),
                    )
                  : Container(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavigationIndex,
        onTap: (index) {
          setState(() {
            bottomNavigationIndex = index;
          });
        },
        //color: Colors.orange,
        //type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.art_track), label: 'Mood Dex'),
          BottomNavigationBarItem(
              icon: Icon(Icons.burst_mode), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
