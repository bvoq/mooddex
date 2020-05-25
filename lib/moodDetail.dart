import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/prefer_universal/html.dart' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mooddex_client/dynamicLinks.dart';
import 'package:url_launcher/url_launcher.dart';

import 'globalState.dart';
import 'guide.dart';
import 'record.dart';
import 'moodRate.dart';
import 'moodGuide.dart';
import 'moodReport.dart';
import 'dynamicLinks.dart';
/*
@JS()
@anonymous
class EmptyObject {
  external EmptyObject();
}*/

void tappedOnMood(BuildContext context, String collectionName) {
  debugPrint("loading mood " + collectionName);
  DocumentReference dr =
      Firestore.instance.collection('moods').document(collectionName);
  dr.get().then((DocumentSnapshot snapshot) async {
    debugPrint("calling le window history");
    //const state = { 'page_id': 1, 'user_id': 5 }
    Record record = Record.fromSnapshot(snapshot);
    changeToMoodDetail(context, record);
  });
}

void changeToMoodDetail(BuildContext context, Record record) {
  if (kIsWeb) {
    String longURLPart1 =
        "/dy/?isi=1508217727&ibi=ch.dekeyser.mooddexClient&imv=1.0.0&link=https%3A%2F%2Fmood-dex.com%2F%3F";
    String longURLPart2 = Uri.encodeComponent(record.collectionName);
    String longURLPart3 = "&si=" + Uri.encodeComponent(record.imageURL);
    String longURLPart4 = "&sd=" +
        Uri.encodeComponent(record.name +
            " is experienced by " +
            record.added.toString() +
            " user" +
            (record.added == 1 ? "!" : "s!"));
    String longURLPart5 = "&amv=0&st=" + Uri.encodeComponent(record.name);
    String longURLPart6 = "&apn=ch.dekeyser.mooddex_client";

    String fullLongURL = longURLPart1 +
        longURLPart2 +
        longURLPart3 +
        longURLPart4 +
        longURLPart5 +
        longURLPart6;
    debugPrint("full long url to push state: " + fullLongURL);
    html.window.history.pushState(null, "", fullLongURL);
  }
  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoodDetail(
          initialRecord: record,
          deviceHeight: MediaQuery.of(context).size.height,
          inSwipe: false,
        ),
      ));
}

class MoodHeader extends SliverPersistentHeaderDelegate {
  final Record record;
  Future<bool> _loadImageFuture;
  double sliverMaxHeight;
  MoodHeader(Record record, double sliverMaxHeight)
      : record = record,
        _loadImageFuture = record.loadImageFromFirebase(),
        sliverMaxHeight = sliverMaxHeight;

  Size size;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    size = MediaQuery.of(context).size;

    if (kIsWeb) {
      return Image.network(record.imageURL,
          width: size.width, height: sliverMaxHeight, fit: BoxFit.cover);
    } else {
      return FutureBuilder(
          future: _loadImageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError || record.image == null) {
                return Center(
                    child: Text("Image could not be loaded.",
                        style: TextStyle(color: Colors.grey)));
              } else {
                return Image.file(File(record.image),
                    width: size.width,
                    height: sliverMaxHeight,
                    fit: BoxFit.cover);
              }
            } else {
              return Center(child: CircularProgressIndicator());
            } // LinearProgressIndicator();
          });
    }
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => sliverMaxHeight; //modify for tablet!! 480

  @override
  double get minExtent => 0;
}

class MoodTitle extends SliverPersistentHeaderDelegate {
  final Record record;
  final double titleHeight;
  MoodTitle(Record record, double titleHeight)
      : record = record,
        titleHeight = titleHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GestureDetector(
      onLongPress: () async {
        return showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext context) {
            return CupertinoActionSheet(
              title: Text('Select option'),
              message: Text('Choose an action.'),
              actions: <Widget>[
                globalState.userRecords.containsKey(record.collectionName)
                    ? CupertinoDialogAction(
                        isDefaultAction: true,
                        child: Text("Remove mood"),
                        onPressed: () async {
                          globalState.removeRating(record).then((vo) {
                            Navigator.of(context).pop();
                          });
                        },
                      )
                    : Container(),
                CupertinoActionSheetAction(
                  child: Text('Report'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => MoodReport(
                            reportType: "mood",
                            reportLocation: record.reference.documentID,
                            reportDescription:
                                "What about this mood constitutes an App Store violation?\n"));
                  },
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                isDefaultAction: true,
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: new BoxDecoration(
          border: new Border.all(
              color: Colors
                  .transparent), //color is transparent so that it does not blend with the actual color specified
          borderRadius: const BorderRadius.all(const Radius.circular(30.0)),
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
        ),
        child: Row(
          children: [
            Expanded(
              /*An expanded widget expands the column to fit the full size.*/
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*2 Creating a container here instead of a Text allows us to add padding!*/

                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      record.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  record.link.length > 0
                      ? InkWell(
                          child: Text(record.link.length > 60
                              ? record.link.substring(0, 60) + "..."
                              : record.link),
                          onTap: () => launch(record.link))
                      : Container(),
                ],
              ),
            ),
            /*3 all part of the same row, sample icon */
            Icon(
              Icons.people,
              color: Theme.of(context).accentColor,
            ),
            Text(" " + record.added.toString(),
                style: TextStyle(color: Theme.of(context).accentColor)),
            Padding(padding: EdgeInsets.only(right: 10)),
            Icon(
              Icons.star,
              color: Theme.of(context).accentColor,
            ),
            Text(record.unweightedScore.toStringAsFixed(1),
                style: TextStyle(color: Theme.of(context).accentColor)),
            /*
          Column(children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).accentColor,
                ),
                Text(" " + record.added.toString()),
                Icon(
                  Icons.star,
                  color: Theme.of(context).accentColor,
                ),
                Text(record.unweightedScore.toStringAsFixed(1)),
              ],
            ),
          ]),
          */
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => titleHeight;

  @override
  double get minExtent => titleHeight;
}

class MoodButtons extends SliverPersistentHeaderDelegate {
  final Record record;
  MoodButtons(Record record) : record = record;

  Column _buildButtonColumn(
          Color color, IconData icon, String label, Function onPress) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPress,
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    List<Widget> buttonWidgets = new List<Widget>();
    buttonWidgets.add(_buildButtonColumn(
        Theme.of(context).accentColor,
        globalState.userRecords.containsKey(record.collectionName)
            ? Icons.thumbs_up_down
            : Icons.add,
        globalState.userRecords.containsKey(record.collectionName)
            ? "EDIT RATING"
            : "ADD MOOD",
        () => showDialog(
            context: context,
            builder: (BuildContext context) => MoodRate(record: record))));
    buttonWidgets.add(_buildButtonColumn(
        Theme.of(context).accentColor,
        Icons.rate_review,
        globalState.userRecords.containsKey(record.collectionName) &&
                globalState
                        .userRecords[record.collectionName].guideText.length >
                    0
            ? 'EDIT GUIDE'
            : 'WRITE GUIDE', () {
      showDialog(
          context: context,
          builder: (BuildContext context) => MoodGuide(record: record));
    }));

    buttonWidgets.add(_buildButtonColumn(
        Theme.of(context).accentColor, Icons.share, 'SHARE', () async {
      await shareMood(record);
    }));

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 24, right: 24),
      decoration: new BoxDecoration(
        border: new Border.all(
            //width: W,
            color: Colors
                .transparent), //color is transparent so that it does not blend with the actual color specified
        borderRadius: const BorderRadius.all(const Radius.circular(30.0)),
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: buttonWidgets,
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => 128.0;

  @override
  double get minExtent => 128.0;
}

class MoodGuides extends StatefulWidget {
  final Record initialRecord;
  MoodGuides({Key key, @required this.initialRecord}) : super(key: key);
  @override
  State<StatefulWidget> createState() => MoodGuidesState();
}

class MoodGuidesState extends State<MoodGuides> {
  MoodGuidesState();

  @override
  Widget build(BuildContext context) {
    debugPrint("loading streambuilder of guides");
    return StreamBuilder<QuerySnapshot>(
      stream: widget.initialRecord.reference
          .collection("guides")
          .orderBy("hf")
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return SliverToBoxAdapter(child: LinearProgressIndicator());

        List<DocumentSnapshot> snaps = snapshot.data.documents;
        List<Guide> guides = List<Guide>(snaps.length);
        for (int i = 0; i < snaps.length; ++i) {
          guides[i] = Guide.fromSnapshot(snaps[i]);
        }
        if (guides.length > 0) {
          globalState.topGuideComment = guides[0].guideText;
        } else {
          globalState.topGuideComment = "";
        }
        guides = guides.where((g) => g.guideText.length > 0).toList();
        return SliverList(
            delegate: SliverChildBuilderDelegate((content, i) {
          return _buildItem(context, guides[i]);
        }, childCount: guides.length));
      },
    );
  }

  Color factorColor(Color a, Color b, double p) {
    return Color.fromRGBO(
        ((p * a.red + (1.0 - p) * b.red) / 1).round(),
        ((p * a.green + (1.0 - p) * b.green) / 1).round(),
        ((p * a.blue + (1.0 - p) * b.blue) / 1).round(),
        (p * a.opacity + (1.0 - p) * b.opacity) / 1);
  }

  Widget _buildItem(BuildContext context, Guide guide) {
    return ListTile(
      title: Container(
        decoration: BoxDecoration(
          border: Border(
              /*
            left: BorderSide(
              color: Colors.transparent,
              width: 15.0,
            ),*/
              /*
            right: BorderSide(
              color: Theme.of(context).accentColor,
              width: 5.0,
            ),*/
              ),
          color: factorColor(Theme.of(context).backgroundColor,
              Theme.of(context).scaffoldBackgroundColor, 0.05),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
          child: Column(
            children: [
              Row(
                  children: guide.rating == 0
                      ? [
                          Text("Unrated",
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 14,
                              )),
                        ]
                      : [
                          Text("Rated: ",
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 14,
                              )),
                          Icon(
                            Icons.star,
                            color: Theme.of(context).accentColor,
                            size: 18,
                          ),
                          Text(
                            guide.rating.toString(),
                            style: TextStyle(
                              color: Theme.of(context).accentColor,
                              fontSize: 14,
                            ),
                          ),
                        ]),
              Text(
                guide.guideText,
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 14),
              ),
              Row(
                children: [
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10))),
                  Text("~ " + guide.author,
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                  /*
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                      Icon(Icons.star, color: Colors.blueGrey),
                      Text(
                        guide.rating.toString(),
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                      */
                ],
              ),
              Padding(padding: EdgeInsets.only(bottom: 4)),
              guide.helpful == 0
                  ? Container()
                  : Row(
                      children: [
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10))),
                        Text(
                          guide.helpful.toString() +
                              (guide.helpful >= 2
                                  ? " people"
                                  : guide.helpful == 1
                                      ? " person"
                                      : " people") +
                              " found this helpful",
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(fontSizeFactor: 0.75, color: Colors.grey),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
      onLongPress: () async {
        return showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext context) {
            return CupertinoActionSheet(
              title: Text('Select option'),
              message: Text('Was the comment helpful?'),
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: Text('Helpful'),
                  onPressed: () {
                    globalState.rateGuide(widget.initialRecord, guide, 1);
                    Navigator.pop(context);
                  },
                ),
                CupertinoActionSheetAction(
                  child: Text('Not helpful'),
                  onPressed: () {
                    globalState.rateGuide(widget.initialRecord, guide, -1);
                    Navigator.pop(context);
                  },
                ),
                CupertinoActionSheetAction(
                  child: Text('Report'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => MoodReport(
                            reportType: "comment",
                            reportLocation:
                                widget.initialRecord.reference.documentID +
                                    "_" +
                                    guide.uid,
                            reportDescription:
                                "What about this comment constitutes an App Store violation?\n"));
                  },
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                isDefaultAction: true,
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class MoodDetail extends StatefulWidget {
  final Record initialRecord;
  final double deviceHeight;
  final bool inSwipe;
  final Key key;
  MoodDetail(
      {this.key,
      @required this.initialRecord,
      @required this.deviceHeight,
      @required this.inSwipe})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      MoodDetailState(initialRecord, deviceHeight, inSwipe);
}

class MoodDetailState extends State<MoodDetail> {
  //make sure record is initialised when sending the data.
  Color color = Color.fromRGBO(0, 0, 255, 0.4);
  MoodHeader header;
  MoodTitle title;
  MoodButtons buttons;
  MoodGuides guides;
  Record record;

  MoodDetailState(Record record, double deviceHeight, bool inSwipe) {
    debugPrint(record.name);
    //sliverMaxHeight

    double heightOfTitle =
        109.0 + (record.link.length > 0 ? (inSwipe ? 2 * 38.0 : 38.0) : 0.0);
    double heightOfHeader = deviceHeight - heightOfTitle;

    //deviceHeight * 1597.0 / 2584 (golden ratio)

    header = MoodHeader(record, heightOfHeader); //golden ratio boys
    title = MoodTitle(record, heightOfTitle);
    buttons = MoodButtons(record);
    guides = MoodGuides(initialRecord: record);
    record = record;
    globalState.addUpdateFunction(callbackMoodDetail);
  }

  void callbackMoodDetail(Record newRecord) {
    debugPrint("Okidok callback mood has been called");
    debugPrint("Votes: " + newRecord.votes.toString());
    record = newRecord;
    //header = MoodHeader(record);
    title = MoodTitle(record, title.titleHeight);
    buttons = MoodButtons(record);
    guides = MoodGuides(initialRecord: record);
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    //return Container(
    //    child: Center(child: Text(widget.initialRecord.collectionName)));

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(""),
          elevation: 0, //no shadows
          backgroundColor: Colors.transparent,
        ),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
                pinned: false, floating: true, delegate: header),
            SliverPersistentHeader(
                pinned: true, floating: false, delegate: title),
            SliverPersistentHeader(
                pinned: false, floating: false, delegate: buttons),
            guides,
          ],
        ));
  }

  @override
  void dispose() {
    if (kIsWeb) html.window.history.pushState(null, "", "");
    super.dispose();
  }
}
