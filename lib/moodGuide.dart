import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'globalState.dart';
import 'record.dart';

class MoodGuide extends StatefulWidget {
  final Record record;
  MoodGuide({Key key, @required this.record}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MoodGuideState(record.collectionName);
}

class MoodGuideState extends State<MoodGuide> {
  TextEditingController _moodGuideController;

  MoodGuideState(String collectionName) {
    if (globalState.userRecords.containsKey(collectionName) &&
        globalState.userRecords[collectionName].guideText.length > 0) {
      _moodGuideController = TextEditingController(
          text: globalState.userRecords[collectionName].guideText);
    } else {
      _moodGuideController = TextEditingController();
    }
  }
  @override
  Widget build(BuildContext context) {
    int rating = 0;
    if (globalState.userRecords.containsKey(widget.record.collectionName)) {
      rating = globalState.userRecords[widget.record.collectionName].rating;
    }
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
              /*
              Padding(
                  padding: const EdgeInsets.only(left: 3, bottom: 6),
                  child: Text(
                    "Some tips for writing a good guide:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),*/
              Padding(
                padding: const EdgeInsets.only(left: 3, bottom: 6),
                child: Text(
                    "Some tips for writing a good guide:\n\n" +
                        "• Describe the mood in 1-3 sentences.\n" +
                        "• Then share how to best experience it.\n" +
                        (rating > 0
                            ? "• Justify your rating of " +
                                rating.toString() +
                                " (pros/cons)."
                            : "• Justify the pros and cons the mood."),
                    style: TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3, top: 16, bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: new BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.2,
                    ),
                    child: TextField(
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blue, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1.0),
                          ),
                          hintStyle: TextStyle(color: Colors.blueGrey),
                          hintText: '\n\n\n'),
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      maxLength: 20000,
                      controller: _moodGuideController,
                    ),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 3, top: 0, bottom: 0),
                  child: CupertinoDialogAction(
                    isDefaultAction: true,
                    child: new Text(globalState.userRecords
                                .containsKey(widget.record.collectionName) &&
                            globalState
                                    .userRecords[widget.record.collectionName]
                                    .guideText
                                    .length >
                                0
                        ? "Edit guide"
                        : "Add guide"),
                    onPressed: () async {
                      assert(widget.record != null);
                      debugPrint(
                          "adding guide: " + widget.record.collectionName);
                      globalState
                          .addGuide(
                        widget.record,
                        _moodGuideController.text,
                      )
                          .then((val) {
                        //widget.callbackMoodDetail(widget.record);
                      });
                      Navigator.of(context).pop();
                    },
                  )),
            ]),
      ),
    );
  }
}
