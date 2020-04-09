import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'globalState.dart';
import 'guide.dart';
import 'record.dart';
import 'moodRate.dart';
import 'moodGuide.dart';

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
                  width: size.width, fit: BoxFit.fitWidth);
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
  double get maxExtent => 235; //modify for tablet!! 480

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
                Text(
                  'Kandersteg, Switzerland',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          /*3 all part of the same row, sample icon */
          Icon(
            Icons.star,
            color: Colors.red,
          ),
          Text(record.unweightedScore.toStringAsFixed(1)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => 108.0;

  @override
  double get minExtent => 108.0;
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
      padding: const EdgeInsets.all(32),
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
              globalState.userRecords.containsKey(record.searchName)
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
              globalState.userRecords.containsKey(record.searchName)
                  ? 'EDIT GUIDE'
                  : 'WRITE GUIDE', () {
            showDialog(
                context: context,
                builder: (BuildContext context) => MoodGuide(record: record));
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
  double get maxExtent => 136.0;

  @override
  double get minExtent => 136.0;
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
    return StreamBuilder<QuerySnapshot>(
      stream: widget.initialRecord.reference
          .collection("guides")
          .orderBy("ts")
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildGuides(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildGuides(BuildContext context, List<DocumentSnapshot> snapshot) {
    List<Widget> guideWidgets =
        snapshot.map((data) => _buildGuideItem(context, data)).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: guideWidgets,
    );
  }

  Widget _buildGuideItem(BuildContext context, DocumentSnapshot snapshot) {
    //final record = Record.fromMap(data); // where Map data
    Guide guide = Guide.fromSnapshot(snapshot);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
            title: Text(guide.guideText),
            trailing: null,
            onTap: () async {
              /*
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoodDetail(initialRecord: record),
                  ));*/
            }
            // Navigator.of(context).push(record.findValue), //print(record),
            ),
      ),
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
    setState(() => {});
  }

  //Color color = Theme.of(context).primaryColor;
  Widget _titleSection() => Container(
        padding: const EdgeInsets.all(32),
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
                  Text(
                    'Kandersteg, Switzerland',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            /*3 all part of the same row, sample icon */
            Icon(
              Icons.star,
              color: Colors.green,
            ),
            Text(record.unweightedScore.toStringAsFixed(1)),
          ],
        ),
      );

  Widget _guideSection() => Container(
        padding: const EdgeInsets.all(32),
        child:
            /*
        return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('moods')
          .where("search_terms", arrayContainsAny: searchTerms)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.documents, query);
      },
    );
    */
            Text(
          'Let me excite you for bubble watching. Next time you come '
          'across an aquarium don\'t bother with the fish but see if '
          'there is a bubble machine. If the bubbles come out at the right '
          'speed it is more interesting than watching a horse race. '
          'The bubbles form teams in forms of rafts, can spontaneously explode '
          'or merge with other bubbles. Similarly if you are next to a lake/ocean, '
          'stop and adore the physics of bubbles.'
          'Let me excite you for bubble watching. Next time you come '
          'across an aquarium don\'t bother with the fish but see if '
          'there is a bubble machine. If the bubbles come out at the right '
          'speed it is more interesting than watching a horse race. '
          'The bubbles form teams in forms of rafts, can spontaneously explode '
          'or merge with other bubbles. Similarly if you are next to a lake/ocean, '
          'stop and adore the physics of bubbles.'
          'Let me excite you for bubble watching. Next time you come '
          'across an aquarium don\'t bother with the fish but see if '
          'there is a bubble machine. If the bubbles come out at the right '
          'speed it is more interesting than watching a horse race. '
          'The bubbles form teams in forms of rafts, can spontaneously explode '
          'or merge with other bubbles. Similarly if you are next to a lake/ocean, '
          'stop and adore the physics of bubbles.'
          'Let me excite you for bubble watching. Next time you come '
          'across an aquarium don\'t bother with the fish but see if '
          'there is a bubble machine. If the bubbles come out at the right '
          'speed it is more interesting than watching a horse race. '
          'The bubbles form teams in forms of rafts, can spontaneously explode '
          'or merge with other bubbles. Similarly if you are next to a lake/ocean, '
          'stop and adore the physics of bubbles.'
          'Let me excite you for bubble watching. Next time you come '
          'across an aquarium don\'t bother with the fish but see if '
          'there is a bubble machine. If the bubbles come out at the right '
          'speed it is more interesting than watching a horse race. '
          'The bubbles form teams in forms of rafts, can spontaneously explode '
          'or merge with other bubbles. Similarly if you are next to a lake/ocean, '
          'stop and adore the physics of bubbles.'
          'Let me excite you for bubble watching. Next time you come '
          'across an aquarium don\'t bother with the fish but see if '
          'there is a bubble machine. If the bubbles come out at the right '
          'speed it is more interesting than watching a horse race. '
          'The bubbles form teams in forms of rafts, can spontaneously explode '
          'or merge with other bubbles. Similarly if you are next to a lake/ocean, '
          'stop and adore the physics of bubbles.',
          softWrap: true,
        ),
      );

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
            SliverToBoxAdapter(child: guides)
          ],
        ));
  }
}
