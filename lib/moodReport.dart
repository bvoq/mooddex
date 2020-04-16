import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodReport extends StatefulWidget {
  final String reportType;
  final String reportLocation;
  final String reportDescription;
  MoodReport(
      {Key key,
      @required this.reportType,
      @required this.reportLocation,
      @required this.reportDescription})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => MoodReportState();
}

class MoodReportState extends State<MoodReport> {
  TextEditingController _reportController;

  MoodReportState() {
    _reportController = TextEditingController();
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
              child: Text("Report " + widget.reportType,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 6),
              child: Text(widget.reportDescription),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3, top: 16, bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  constraints: new BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
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
                    controller: _reportController,
                  ),
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 3, top: 8, bottom: 0),
                child: CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text("Create feedback"),
                  onPressed: () async {
                    await Firestore.instance.collection("reports").add({
                      "rt": widget.reportType,
                      "rl": widget.reportLocation,
                      "co": _reportController.text,
                      "ts": FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }
}
