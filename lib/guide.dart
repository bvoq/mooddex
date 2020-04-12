import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class Guide {
  String author_uid;
  String guideText;
  int rating;
  int category;
  int helpful;
  int unhelpful;
  Timestamp ts;
  Guide(String _author_uid, String _guideText, int _rating, int _category,
      int _helpful, Timestamp _ts)
      : author_uid = _author_uid,
        guideText = _guideText,
        ts = _ts,
        rating = _rating,
        category = _category,
        helpful = _helpful;

  Guide.fromMap(Map<String, dynamic> map)
      : assert(map["uid"] != null),
        assert(map["gu"] != null),
        //assert(map["ts"] != null),
        assert(map["ra"] != null),
        assert(map["ca"] != null),
        assert(map["hf"] != null),
        //assert(map["uhf"] != null),
        author_uid = map["uid"],
        guideText = map["gu"],
        rating = map["ra"],
        category = map["ca"],
        helpful = map["hf"],
        ts = map["ts"];

  Guide.fromSnapshot(DocumentSnapshot snapshot) : this.fromMap(snapshot.data);
}
