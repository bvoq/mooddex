import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'stopwords.dart';

class IDPair {
  int a;
  double b;
  IDPair(int a, double b)
      : a = a,
        b = b;
}

class Record {
  final String name;
  final int added;
  final List<int> votes;
  final int totalvotes;
  File imageFile;
  double unweightedScore;
  double score;
  bool uploaded;
  DocumentReference reference;
  /*Record()
      : name = "",
        added = 0,
        votes = [],
        totalvotes = 0,
        reference = null;
  */

  /*
  Weighted Score = (v / (v + m)) * S + (m / (v + m)) * C
  S = Average score for the anime/manga
  v = Number users giving a score for the anime/manga †
  m = Minimum number of scored users required to get a calculated score
  C = The mean score across the entire Anime/Manga database
  */

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        assert(map['added'] != null),
        assert(map['votes'].length == 10),
        assert(map['search_terms'] != null),
        name = map['name'],
        added = map['added'],
        votes = map['votes'].cast<int>(),
        //votes = map['votes'].map((s) => s as int).toList(),
        totalvotes = map['votes'].reduce((a, b) => a + b),
        uploaded = true,
        imageFile = null,
        unweightedScore = map['votes']
            .fold(
                IDPair(1, 0),
                (p, val) => IDPair(p.a + 1,
                    p.b + p.a * val / map['votes'].reduce((a, b) => a + b)))
            .b;

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Record.fromInitializer(
      String name, int added, List<int> votes, int totalvotes)
      : assert(votes.length == 10),
        assert(name.length > 3 && name.length <= 45),
        name = name,
        added = added,
        votes = votes,
        totalvotes = totalvotes,
        uploaded = false;
/* TODO
  Future<String> uploadImage(var imageFile) async {
    String searchName =
        name.toString().toLowerCase().toUpperCase().toLowerCase();
    StorageReference ref = storage.ref().child("images/" + searchName + ".jpg");
    StorageUploadTask uploadTask = ref.putFile(imageFile);

    var dowurl = await (await uploadTask.onComplete).ref.getDownloadURL();
    url = dowurl.toString();

    return url;
  }*/

  Future<void> publish() async {
    if (uploaded == true)
      return;
    else {
      String searchName =
          name.toString().toLowerCase().toUpperCase().toLowerCase();
      List<String> searchWords = searchName
          .split(" ")
          .where((i) => (i.length > 2 && !stopwords.contains(i)))
          .toList();
      List<String> searchTerms = [];
      for (int i = 0; i < searchWords.length; ++i) {
        for (int j = 3; j <= searchWords[i].length; ++j) {
          searchTerms.add(searchWords[i].substring(0, j));
        }
      }

      DocumentSnapshot ds = await Firestore.instance
          .collection('moods')
          .document(searchName)
          .get()
          .catchError((onError) {
        debugPrint('Seems to be offline.');
        return;
      });
      if (ds.exists) {
        reference = ds.reference;
        uploaded = true;
        return;
      } else {
        //first upload the image, then upload the firestore instance.

        await Firestore.instance
            .collection('moods')
            .document(searchName)
            .setData({
          'name': name,
          'search_terms': searchTerms,
          'votes': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          'added': 1,
        }).then((onValue) {
          uploaded = true;
        }).catchError((onError) {});
        return;
      }
    }
  }

  @override
  String toString() => "Record<$name:$added:$votes>";
}
