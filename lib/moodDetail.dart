import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'globalState.dart';
import 'guide.dart';
import 'record.dart';
import 'moodRate.dart';
import 'moodGuide.dart';
import 'moodReport.dart';

class MoodHeader extends SliverPersistentHeaderDelegate {
  final Record record;
  Future<bool> _loadImageFuture;
  MoodHeader(Record record)
      : record = record,
        _loadImageFuture = record.loadImageFromFirebase();

  Size size;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    size = MediaQuery.of(context).size;

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
                  width: size.width, height: 300, fit: BoxFit.cover);
            }
          } else {
            return Center(child: CircularProgressIndicator());
          } // LinearProgressIndicator();
        });

    /*Image.asset('./images/bubbles.jpg',
        width: size.width,
        //height: MediaQuery.of(context).size.height / 4,
        fit: BoxFit.fitWidth);
    */
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => 300; //modify for tablet!! 480

  @override
  double get minExtent => 0;
}

class MoodTitle extends SliverPersistentHeaderDelegate {
  final Record record;
  MoodTitle(Record record) : record = record;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
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
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => 108.0 + (record.link.length > 0 ? 37 : 0);

  @override
  double get minExtent => 108.0 + (record.link.length > 0 ? 37 : 0);
}

class MoodButtons extends SliverPersistentHeaderDelegate {
  final Record record;
  final Function callbackMoodDetail;
  MoodButtons(Record record, Function callbackMoodDetail)
      : record = record,
        callbackMoodDetail = callbackMoodDetail;

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
        children: [
          _buildButtonColumn(
              Theme.of(context).accentColor,
              Icons.thumbs_up_down,
              globalState.userRecords.containsKey(record.collectionName)
                  ? "EDIT RATING"
                  : "ADD MOOD",
              () => showDialog(
                  context: context,
                  builder: (BuildContext context) => MoodRate(
                      record: record, callbackMoodDetail: callbackMoodDetail))),
          //_buildButtonColumn(
          //    Theme.of(context).accentColor, Icons.archive, 'TODO MOOD', () {}),
          _buildButtonColumn(
              Theme.of(context).accentColor,
              Icons.rate_review,
              globalState.userRecords.containsKey(record.collectionName) &&
                      globalState.userRecords[record.collectionName].guideText
                              .length >
                          0
                  ? 'EDIT GUIDE'
                  : 'WRITE GUIDE', () {
            showDialog(
                context: context,
                builder: (BuildContext context) => MoodGuide(
                    record: record, callbackMoodDetail: callbackMoodDetail));
          }),
          _buildButtonColumn(
              Theme.of(context).accentColor, Icons.share, 'SHARE', () {}),
        ],
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
          .orderBy("ts")
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return SliverToBoxAdapter(child: LinearProgressIndicator());

        List<DocumentSnapshot> snaps = snapshot.data.documents;
        List<Guide> guides = List<Guide>(snaps.length);
        for (int i = 0; i < snaps.length; ++i) {
          guides[i] = Guide.fromSnapshot(snaps[i]);
        }
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
  MoodDetail({Key key, @required this.initialRecord}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MoodDetailState(initialRecord);
}

class MoodDetailState extends State<MoodDetail> {
  //make sure record is initialised when sending the data.
  Color color = Color.fromRGBO(0, 0, 255, 0.4);
  MoodHeader header;
  MoodTitle title;
  MoodButtons buttons;
  MoodGuides guides;
  Record record;

  MoodDetailState(Record record) {
    debugPrint(record.name);
    header = MoodHeader(record);
    title = MoodTitle(record);
    buttons = MoodButtons(record, callbackMoodDetail);
    guides = MoodGuides(initialRecord: record);
    record = record;
  }

  void callbackMoodDetail(Record newRecord) {
    debugPrint("Okidok callback mood has been called");
    debugPrint("Votes: " + newRecord.votes.toString());
    record = newRecord;
    //header = MoodHeader(record);
    title = MoodTitle(record);
    buttons = MoodButtons(record, callbackMoodDetail);
    guides = MoodGuides(initialRecord: record);
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
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
}
