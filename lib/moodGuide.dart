import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:flutter/cupertino.dart';

import 'globalState.dart';
import 'record.dart';

class MoodGuide extends StatefulWidget {
  final Record record;
  MoodGuide({Key key, @required this.record}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MoodGuideState(record.searchName);
}

class MoodGuideState extends State<MoodGuide> {
  TextEditingController _moodGuideController;

  MoodGuideState(String searchName) {
    if (globalState.userRecords.containsKey(searchName) &&
        globalState.userRecords[searchName].guideText.length > 0) {
      _moodGuideController = TextEditingController(
          text: globalState.userRecords[searchName].guideText);
    } else {
      _moodGuideController = TextEditingController();
    }
  }
  @override
  Widget build(BuildContext context) {
    int rating = 0;
    if (globalState.userRecords.containsKey(widget.record.searchName)) {
      rating = globalState.userRecords[widget.record.searchName].rating;
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
              Padding(
                padding: const EdgeInsets.only(left: 0, bottom: 24),
                child: Text(widget.record.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3, bottom: 6),
                child: Text(
                    "Some tips for writing a good guide:\n\n• Describe in 1-3 sentences what \n   " +
                        widget
                            .record.name
                            .toLowerCase()
                            .toUpperCase()
                            .toLowerCase() +
                        " is.\n• Share how best to experience\n   " +
                        widget
                            .record.name
                            .toLowerCase()
                            .toUpperCase()
                            .toLowerCase() +
                        ".\n• " +
                        (rating >
                                0
                            ? "Justify your rating of " +
                                rating.toString() +
                                " (pros/cons)."
                            : "Justify the pros/cons of \n   " +
                                widget.record.name
                                    .toLowerCase()
                                    .toUpperCase()
                                    .toLowerCase() +
                                ".\n")),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3, top: 16, bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: new BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: TextField(
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
                      controller: _moodGuideController,
                    ),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 3, top: 48, bottom: 0),
                  child: CupertinoDialogAction(
                    isDefaultAction: true,
                    child: new Text("Add guide"),
                    onPressed: () {
                      assert(widget.record != null);
                      debugPrint("adding guide: " + widget.record.searchName);
                      globalState.addGuide(
                        widget.record,
                        _moodGuideController.text,
                      );
                      Navigator.of(context).pop();
                    },
                  )),
            ]),
      ),
    );
  }
}