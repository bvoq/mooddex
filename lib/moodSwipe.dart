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

      Firestore.instance
          .collection('moods')
          .orderBy('rnd')
          .startAt([val])
          .limit(count - cards.length + 2)
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
        top: 100 - 60.0 * (qs - i - 1),
        duration: Duration(milliseconds: 100),
        curve: Curves.easeInOutCubic,
        child: Dismissible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(75),
            child: AnimatedOpacity(
              // If the widget is visible, animate to 0.0 (invisible).
              // If the widget is hidden, animate to 1.0 (fully visible).
              opacity: qs - i > 3 ? 0.0 : 1.0,
              duration: Duration(milliseconds: 500),
              child: AnimatedContainer(
                  width:
                      //MediaQuery.of(context).size.width / 1.5,
                      max(
                          MediaQuery.of(context).size.width / 1.5 -
                              (qs - i - 1) * 70,
                          MediaQuery.of(context).size.width / 1.5 - 2 * 70),
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
