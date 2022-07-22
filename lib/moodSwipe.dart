//idea: load a few moods and swipe left/right on them

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'moodAdd.dart';
import 'record.dart';
import 'moodDetail.dart';
import 'moodSearch.dart';

class MoodSwipe extends StatefulWidget {
  final double width, height;
  MoodSwipe({Key key, @required this.width, @required this.height})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => MoodSwipeState(width, height);
}

class MoodSwipeState extends State<MoodSwipe> {
  List<MoodDetail> cards = List<MoodDetail>();
  //Queue<Widget> cardDisplay = Queue<Widget>(); // split into MoodDetail and Record and always just transfer one from mooddetail to record!!

  List<Widget> displayCards = [];
  bool initialLoad;
  Future<bool> initialLoadF;

  MoodSwipeState(double width, double height) {
    loadCards(width, height, 6, true);
  }

  void loadCards(double width, double height, int count, bool refresh) {
    Random rnd = new Random();
    if (cards.length < count) {
      double val = rnd.nextDouble();

      FirebaseFirestore.instance
          .collection('moods')
          .orderBy('rnd')
          .startAt([val])
          .limit(count - cards.length + 2)
          /*
          .where('searchable', isEqualTo: true)
          .limit(1)*/
          .get()
          .catchError((onError) {
            debugPrint("error loading cards");
            initialLoad = false;
            initialLoadF = Future<bool>.value(false);
            //return;
          })
          .then((QuerySnapshot snap) {
            if (snap != null) {
              debugPrint(snap.docs.length.toString());
              List<DocumentSnapshot> snaps = snap.docs;
              for (int i = 0; i < snaps.length && cards.length < count; ++i) {
                Record record = Record.fromSnapshot(snaps[i]);
                if (record.searchable) {
                  MoodDetail mood = MoodDetail(
                    key: UniqueKey(),
                    initialRecord: record,
                    deviceHeight: height / 1.45,
                    inSwipe: true,
                  );
                  cards.add(mood);
                }
              }
              loadCards(width, height, count, refresh);
              if (snaps.length < 1) {
                initialLoad = false;
                initialLoadF = Future<bool>.value(false);
              }
              return;
            } else {
              initialLoad = false;
              initialLoadF = Future<bool>.value(false);
              return;
            }
          });
    } else {
      debugPrint("setstater " + cards.length.toString());
      matchCards();
      if (refresh) setState(() {});
      for (int i = 0; i < displayCards.length; ++i) {
        cards[i].createState();
      }
      debugPrint("LOADED CARDS " +
          displayCards.length.toString() +
          " " +
          cards.length.toString());
    }
    initialLoad = true;
    initialLoadF = Future<bool>.value(true);
  }

  void matchCards() {
    int qs = cards.length;
    displayCards = List<Widget>();
    bool moreCards = (displayCards.length != cards.length);
    for (int i = displayCards.length; i < cards.length; ++i) {
      displayCards.add(AnimatedPositioned(
        key: cards[qs - i - 1].key,
        top: 60 - 20.0 * (qs - i - 1),
        duration: Duration(milliseconds: 100),
        curve: Curves.easeInOutCubic,
        child: Dismissible(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(MediaQuery.of(context).size.width / 20),
            child: AnimatedOpacity(
              // If the widget is visible, animate to 0.0 (invisible).
              // If the widget is hidden, animate to 1.0 (fully visible).
              opacity: qs - i > 3 ? 0.0 : 1.0,
              duration: Duration(milliseconds: 500),
              child: AnimatedContainer(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        spreadRadius: 10,
                        blurRadius: 5,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  width:
                      //MediaQuery.of(context).size.width / 1.5,
                      max(
                          min(512.0, MediaQuery.of(context).size.width / 1.1) -
                              (qs - i - 1) * 30,
                          min(512.0, MediaQuery.of(context).size.width / 1.1) -
                              2 * 30),
                  curve: Curves.bounceInOut,
                  height: MediaQuery.of(context).size.height / 1.5,
                  duration: Duration(milliseconds: 100),
                  child: cards[qs - i - 1]),
            ),
          ),
          key: cards[qs - i - 1].key,
          onDismissed: (direction) {
            debugPrint("remove " + (qs - i - 1).toString());
            cards.removeAt(qs - i - 1);
            displayCards.removeAt(qs - i - 1);
            matchCards();
            setState(() {});
            if (cards.length < 7) {
              loadCards(MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height, 20, false);
            }
          },
        ),
      ));
    }
  }

  @override
  build(BuildContext context) {
    debugPrint("building " + cards.length.toString());
    Widget fb = FutureBuilder(
        future: initialLoadF,
        builder: (context, snapshot) {
          int qs = min(3, cards.length);
          if (cards.length == 0) {
            debugPrint("actually circulating");
            return Center(child: CircularProgressIndicator());
          } else {
            return Container(
              child: Column(
                children: [
                  CupertinoNavigationBar(
                    middle: Text("Discover Moods"),
                    leading: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MoodAdd(
                                query: "",
                                callback: () {
                                  debugPrint("Called callback!!!");
                                  setState(() {
                                    cards = [];
                                    displayCards = [];
                                  });
                                  loadCards(
                                      widget.width, widget.height, 6, true);
                                  setState(() {});
                                }),
                          )),
                      child: Icon(
                        CupertinoIcons.add,
                        color: CupertinoColors.black,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        showSearch(
                          context: context,
                          delegate: MoodSearchMaterial(),
                        );
                      },
                      child: Icon(
                        CupertinoIcons.search,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 151,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: displayCards,
                    ),
                  ),
                ],
              ),
            );
          }
        });
    debugPrint("end building " + cards.length.toString());
    return fb;
  }
}
