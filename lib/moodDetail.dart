import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'record.dart';

class MoodHeader extends SliverPersistentHeaderDelegate {
  final Record record;
  MoodHeader(Record record) : record = record;

  Size size;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    size = MediaQuery.of(context).size;
    return Image.asset('./images/bubbles.jpg',
        width: size.width,
        //height: MediaQuery.of(context).size.height / 4,
        fit: BoxFit.fitWidth);
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => 235;

  @override
  double get minExtent => 0.0;
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
            //width: W,
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
  MoodButtons(Record record) : record = record;

  Column _buildButtonColumn(Color color, IconData icon, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonColumn(
              Theme.of(context).accentColor, Icons.thumbs_up_down, 'ADD MOOD'),
          _buildButtonColumn(
              Theme.of(context).accentColor, Icons.archive, 'TODO MOOD'),
          _buildButtonColumn(
              Theme.of(context).accentColor, Icons.rate_review, 'WRITE GUIDE'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;

  @override
  double get maxExtent => 112.0;

  @override
  double get minExtent => 112.0;
}

class MoodDetail extends StatelessWidget {
  //make sure record is initialised when sending the data.
  final Record record;
  final Color color = Color.fromRGBO(0, 0, 255, 0.4);
  final MoodHeader header;
  final MoodTitle title;
  final MoodButtons buttons;
  MoodDetail({Key key, @required this.record})
      : header = MoodHeader(record),
        title = MoodTitle(record),
        buttons = MoodButtons(record),
        super(key: key);

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
              color: Colors.red,
            ),
            Text(record.unweightedScore.toStringAsFixed(1)),
          ],
        ),
      );

  Widget _guideSection() => Container(
        padding: const EdgeInsets.all(32),
        child: Text(
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
                pinned: true, floating: true, delegate: buttons),
            SliverToBoxAdapter(child: _guideSection())
            /*
            Column(
              children: [
                Image.asset('./images/bubbles.jpg',
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 4,
                    fit: BoxFit.cover),
                _titleSection(),
                _buttonSection(),
                _guideSection()
              ],
            )*/
          ],
        ));
  }
}
