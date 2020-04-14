import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'moodSearch.dart';
import 'moodDetail.dart';
import 'moodReport.dart';
import 'globalState.dart';
import 'login.dart';
import 'record.dart';
import 'register.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class MyMoods extends StatefulWidget {
  @override
  MyMoodsState createState() => MyMoodsState();
}

class MyMoodsState extends State<MyMoods> {
  List<RecordUser> records;
  List<int> sortingOrders = [1, 1, -1];
  int currentSortedIndex;

  MyMoodsState() {
    loadMyMoods(2, true);
    globalState.addUpdateFunction(() {
      loadMyMoods(currentSortedIndex, false);
      return;
    });
  }

  void loadMyMoods(int index, bool constructor) {
    assert(index >= 0 && index <= 2);
    if (currentSortedIndex == index)
      sortingOrders[index] = -sortingOrders[index];

    currentSortedIndex = index;
    records = globalState.userRecords.entries.map((e) => e.value).toList();
    //now sort according to selected criteria.
    records.sort((a, b) {
      if (index == 0) {
        return sortingOrders[index] *
            a.collectionName.compareTo(b.collectionName);
      } else if (index == 1) {
        return sortingOrders[index] * a.category.compareTo(b.category);
      } else if (index == 2) {
        return sortingOrders[index] * a.rating.compareTo(b.rating);
      }
      return 0;
    });

    if (!constructor) setState(() => {}); //call build function again.
  }

  void tappedOnMood(RecordUser recordUser) {
    DocumentReference dr = Firestore.instance
        .collection('moods')
        .document(recordUser.collectionName);
    dr.get().then((DocumentSnapshot snapshot) {
      Record record = Record.fromSnapshot(snapshot);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoodDetail(initialRecord: record),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverStickyHeader(
      overlapsContent: true,
      header: Container(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.98),
        child: DataTable(
          sortColumnIndex: currentSortedIndex,
          sortAscending: sortingOrders[currentSortedIndex] >= 0,
          columns: [
            DataColumn(
              label: Text("Name"),
              onSort: (columnIndex, sortAscending) =>
                  loadMyMoods(columnIndex, false),
            ),
            DataColumn(
              label: Text("Category"),
              onSort: (columnIndex, sortAscending) =>
                  loadMyMoods(columnIndex, false),
              numeric: true,
            ),
            DataColumn(
                label: Text("Rating"),
                onSort: (columnIndex, sortAscending) =>
                    loadMyMoods(columnIndex, false),
                numeric: true),
          ],
          rows: [],
        ),
      ),
      sliver: SliverToBoxAdapter(
        child: Container(
          child: DataTable(
            columns: [
              DataColumn(
                label: Container(),
              ),
              DataColumn(
                label: Container(),
                numeric: true,
              ),
              DataColumn(label: Container(), numeric: true),
            ],
            rows: records
                .map(
                  (recordUser) => DataRow(
                    cells: [
                      DataCell(Text(recordUser.name),
                          onTap: () => tappedOnMood(recordUser)),
                      DataCell(
                          Text(recordUser.category == 0
                              ? "I do this"
                              : recordUser.category == 1
                                  ? "I did this"
                                  : recordUser.category == 2
                                      ? "I will do this"
                                      : ""),
                          onTap: () => tappedOnMood(recordUser)),
                      DataCell(
                          Text(recordUser.rating == 0
                              ? "Unrated"
                              : recordUser.rating.toString()),
                          placeholder: recordUser.rating == 0,
                          onTap: () => tappedOnMood(recordUser)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    /*
    return SliverList(
        delegate: SliverChildBuilderDelegate((content, i) {
      return _buildItem(context, records[i]);
    }, childCount: records.length));
    */
  }
}

class MoodHome extends StatefulWidget {
  @override
  MoodHomeState createState() => MoodHomeState();
}

class MoodHomeState extends State<MoodHome> {
  int bottomNavigationIndex;
  MyMoods myMoods;

  MoodHomeState() {
    bottomNavigationIndex = 0;
    myMoods = MyMoods();
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
          ? CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(largeTitle: Text("My Moods")),
                myMoods,
              ],
            )
          : bottomNavigationIndex == 1
              ? Container(
                  child: Column(
                    children: [
                      CupertinoNavigationBar(middle: Text("My Profile")),
                      Spacer(flex: 1),
                      Text("User: " + globalState.userName),
                      Spacer(flex: 6),
                      globalState.user.isAnonymous
                          ? Center(
                              child: RaisedButton(
                                child:
                                    Text("Register and link anonymous account"),
                                color: Theme.of(context).primaryColor,
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RegisterPage(),
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
      floatingActionButton: FloatingActionButton(
        isExtended: true,
        mini: true,
        child: Icon(Icons.search),
        onPressed: () => showSearch(
          context: context,
          delegate: MoodSearchMaterial(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavigationIndex,
        onTap: (index) {
          setState(() {
            bottomNavigationIndex = index;
          });
        },
        //color: Colors.orange,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.art_track), title: Text('My Moods')),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), title: Text('Profile')),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
