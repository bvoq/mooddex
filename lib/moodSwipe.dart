//idea: load a few moods and swipe left/right on them

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'moodReport.dart';
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
  List<MoodDetail> cards = [];
  bool initialLoad;
  Future<bool> initialLoadF;

  MoodSwipeState(double width, double height) {
    loadCards(width, height, 10);
  }

  void loadCards(double width, double height, int count) {
    Random rnd = new Random();
    debugPrint("testsofar");
    if (cards.length < count) {
      double val = rnd.nextDouble();
      debugPrint("loading");

      Firestore.instance
          .collection('moods')
          .orderBy('rnd')
          .startAt([val])
          .limit(count - cards.length)
          /*
          .where('searchable', isEqualTo: true)
          .limit(1)*/
          .getDocuments()
          .catchError((onError) {
            debugPrint("error loading cards");
            initialLoad = false;
            initialLoadF = Future<bool>.value(false);
            return;
          })
          .then((QuerySnapshot snap) {
            debugPrint("pog: " + snap.toString());

            if (snap != null) {
              debugPrint(snap.documents.length.toString());
              List<DocumentSnapshot> snaps = snap.documents;
              for (int i = 0; i < snaps.length && cards.length < count; ++i) {
                Record record = Record.fromSnapshot(snaps[i]);
                if (record.searchable) {
                  MoodDetail mood = MoodDetail(
                    key: UniqueKey(),
                    initialRecord: record,
                    deviceHeight: height / 1.5,
                  );
                  cards.add(mood);
                }
              }
              loadCards(width, height, count);
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
      setState(() {});
    }
    initialLoad = true;
    initialLoadF = Future<bool>.value(true);
  }

  @override
  build(BuildContext context) {
    return FutureBuilder(
        future: initialLoadF,
        builder: (context, snapshot) {
          if (cards.length == 0) {
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
                            builder: (context) => MoodAdd(query: ""),
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
                    height: MediaQuery.of(context).size.height - 120,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: List.generate(
                        cards.length,
                        (i) => AnimatedPositioned(
                          top: 100 - 60.0 * (cards.length - i - 1),
                          duration: Duration(milliseconds: 100),
                          curve: Curves.easeInOutCubic,
                          child: Dismissible(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(75),
                              child: AnimatedOpacity(
                                // If the widget is visible, animate to 0.0 (invisible).
                                // If the widget is hidden, animate to 1.0 (fully visible).
                                opacity: i + 3 < cards.length ? 0.0 : 1.0,
                                duration: Duration(milliseconds: 500),
                                child: AnimatedContainer(
                                    width:
                                        //MediaQuery.of(context).size.width / 1.5,
                                        max(
                                            MediaQuery.of(context).size.width /
                                                    1.5 -
                                                (cards.length - i - 1) * 70,
                                            MediaQuery.of(context).size.width /
                                                    1.5 -
                                                2 * 70),
                                    curve: Curves.bounceInOut,
                                    height: MediaQuery.of(context).size.height /
                                        1.5,
                                    duration: Duration(milliseconds: 100),
                                    child: cards[cards.length - i - 1]),
                              ),
                            ),
                            key: cards[cards.length - i - 1].key,
                            onDismissed: (direction) {
                              setState(() {
                                cards.removeAt(cards.length - i - 1);
                              });
                              if (cards.length < 5)
                                loadCards(
                                  MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.height,
                                  30,
                                );
                            },
                          ),
                          /*: ClipRRect(
                                  borderRadius: BorderRadius.circular(75),
                                  child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          1.5,
                                      height:
                                          MediaQuery.of(context).size.height /
                                              1.5,
                                      child: cards[cards.length - i - 1]),
                                ),*/
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        });
  }
}

/*
List<Widget> _getMatchCard() { 
    List<MatchCard> cards = new List(); 
    cards.add(MatchCard(255, 0, 0, 10)); 
    cards.add(MatchCard(0, 255, 0, 20)); 
    cards.add(MatchCard(0, 0, 255, 30)); 
    List<Widget> cardList = new List(); 
   for (int x = 0; x < 3; x++) { 
     cardList.add(Positioned( 
       top: cards[x].margin, 
       child: Draggable( 
          onDragEnd: (drag){ 
            _removeCard(x); 
          }, 
       childWhenDragging: Container(), 
       feedback: Card( 
         elevation: 12, 
         color: Color.fromARGB(255, cards[x].redColor, cards[x].greenColor, cards[x].blueColor), 
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
         child: Container( 
            width: 240, 
            height: 300, 
            ), 
          ), 
       child: Card( 
         elevation: 12, 
         color: Color.fromARGB(255, cards[x].redColor, cards[x].greenColor, cards[x].blueColor), 
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
         child: Container( 
           width: 240, 
           height: 300, 
          ), 
         ), 
       ), 
     )
   ); 
  } 
  return cardList;
}
*/
