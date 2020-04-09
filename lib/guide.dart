import 'package:cloud_firestore/cloud_firestore.dart';

class Guide {
  String author;
  String guideText;
  Timestamp ts;
  Guide(String _author, String _guideText, Timestamp _ts)
      : author = _author,
        guideText = _guideText,
        ts = _ts;

  Guide.fromMap(Map<String, dynamic> map)
      : assert(map["au"] != null),
        assert(map["gu"] != null),
        assert(map["ts"] != null),
        author = map["au"],
        guideText = map["gu"],
        ts = map["ts"];

  Guide.fromSnapshot(DocumentSnapshot snapshot) : this.fromMap(snapshot.data);
}
