import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:flutter/cupertino.dart';

import 'globalState.dart';
import 'record.dart';

class MoodRate extends StatefulWidget {
  final Record record;
  MoodRate({Key key, @required this.record}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MoodRateState(record.collectionName);
}

class MoodRateState extends State<MoodRate> {
  double _ratingForStars;
  int rating;
  int category;
  MoodRateState(String collectionName)
      : _ratingForStars = 0,
        rating = 0,
        category = 0 {
    assert(globalState.userRecords != null);

    if (globalState.userRecords.containsKey(collectionName)) {
      rating = globalState.userRecords[collectionName].rating;
      _ratingForStars = rating.toDouble();
      category = globalState.userRecords[collectionName].category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: Container(
        //color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.all(5),
        decoration: new BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 24),
              child: Text(widget.record.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 6),
              child: Text("Rate:"),
            ),
            Row(children: [
              Expanded(
                child: SmoothStarRating(
                    allowHalfRating: false,
                    onRatingChanged: (v) {
                      _ratingForStars = v;
                      rating = _ratingForStars.ceil();
                      setState(() {});
                    },
                    starCount: 10,
                    rating: _ratingForStars,
                    size: MediaQuery.of(context).size.width * 0.059,
                    filledIconData: Icons.star,
                    color: rating == 0 ? Colors.grey : Colors.green,
                    borderColor: rating == 0 ? Colors.grey : Colors.green,
                    spacing: 0.0),
              ),
              Text(rating == 0 ? "⍉" : rating.toString(),
                  style: TextStyle(
                      color: rating == 0 ? Colors.grey : Colors.green))
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 3, top: 16, bottom: 8),
              child: Text("Category:"),
            ),
            CupertinoSlidingSegmentedControl(
                groupValue: category,
                children: const <int, Widget>{
                  0: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      child: Text("I do this", style: TextStyle(fontSize: 12))),
                  1: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      child:
                          Text("I did this", style: TextStyle(fontSize: 12))),
                  2: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      child: Text("I will do this",
                          style: TextStyle(fontSize: 11))),
                },
                onValueChanged: (i) {
                  setState(() {
                    category = i;
                  });
                }),
            Padding(
              padding: const EdgeInsets.only(left: 3, top: 48, bottom: 0),
              child: CupertinoDialogAction(
                isDefaultAction: true,
                child: globalState.userRecords
                        .containsKey(widget.record.collectionName)
                    ? Text("Change rating")
                    : Text("Add mood"),
                onPressed: () {
                  assert(widget.record != null);
                  debugPrint("adding mood: " + widget.record.collectionName);
                  Navigator.of(context).pop();
                  globalState
                      .addRating(widget.record, rating, category)
                      .then((newRecord) {
                    //widget.callbackMoodDetail(newRecord);
                  });
                },
              ),
            ),
            globalState.userRecords.containsKey(widget.record.collectionName)
                ? Padding(
                    padding: const EdgeInsets.only(left: 3, top: 8, bottom: 0),
                    child: CupertinoDialogAction(
                      isDefaultAction: false,
                      child: Text("Remove mood",
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        globalState.removeRating(widget.record);
                      },
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
