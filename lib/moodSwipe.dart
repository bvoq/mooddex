//idea: load a few moods and swipe left/right on them

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'moodReport.dart';
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
    loadCards(width, height);
  }

  void loadCards(double width, double height) {
    Random rnd = new Random();
    debugPrint("testsofar");
    if (cards.length < 5) {
      double val = rnd.nextDouble();
      debugPrint("loading");

      Firestore.instance
          .collection('moods')
          .orderBy('rnd')
          .startAt([val])
          .limit(5 - cards.length)
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
              for (int i = 0; i < snaps.length && cards.length < 5; ++i) {
                Record record = Record.fromSnapshot(snaps[i]);
                MoodDetail mood = MoodDetail(
                  key: UniqueKey(),
                  initialRecord: record,
                  deviceHeight: height / 1.5,
                );
                cards.add(mood);
                loadCards(width, height);
              }
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
              color:
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.98),
              child: Column(
                children: [
                  CupertinoNavigationBar(
                    middle: Text("Discover Moods"),
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
                        (i) => Positioned(
                          top: 40 + 20.0 * i,
                          child: (i + 1 == cards.length)
                              ? Dismissible(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(75),
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                1.5,
                                        height:
                                            MediaQuery.of(context).size.height /
                                                1.5,
                                        child: cards[cards.length - i - 1]),
                                  ),
                                  key: cards[cards.length - i - 1].key,
                                  onDismissed: (direction) {
                                    cards.removeAt(cards.length - i - 1);
                                    loadCards(
                                      MediaQuery.of(context).size.width,
                                      MediaQuery.of(context).size.height,
                                    );
                                  },
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(75),
                                  child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          1.5,
                                      height:
                                          MediaQuery.of(context).size.height /
                                              1.5,
                                      child: cards[cards.length - i - 1]),
                                ),
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
