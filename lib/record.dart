import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import 'package:http/http.dart' show get;
import 'package:path_provider/path_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'globalState.dart';
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
  final String author;
  final String collectionName;

  List<int> votes;
  int totalvotes;
  int added;
  File imageFileToBeUploaded; //used when uploading a record
  String imageURL;
  String image;
  double unweightedScore;
  double score;
  bool uploaded;
  DocumentReference reference;
  final bool searchable;
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
        assert(map['votes_0'] != null),
        assert(map['votes_1'] != null),
        assert(map['votes_2'] != null),
        assert(map['votes_3'] != null),
        assert(map['votes_4'] != null),
        assert(map['votes_5'] != null),
        assert(map['votes_6'] != null),
        assert(map['votes_7'] != null),
        assert(map['votes_8'] != null),
        assert(map['votes_9'] != null),
        assert(map['votes_10'] != null),
        assert(map['search_terms'] != null),
        assert(map['image_ref'] != null),
        assert(map['searchable'] != null),
        assert(map['author'] != null),
        name = map['name'],
        added = map['added'],
        //votes = map['votes'].cast<int>(),
        votes = [
          map['votes_0'],
          map['votes_1'],
          map['votes_2'],
          map['votes_3'],
          map['votes_4'],
          map['votes_5'],
          map['votes_6'],
          map['votes_7'],
          map['votes_8'],
          map['votes_9'],
          map['votes_10']
        ],
        //votes = map['votes'].map((s) => s as int).toList(),
        uploaded = true,
        imageURL = map['image_ref'],
        imageFileToBeUploaded = null,
        image = null,
        searchable = map['searchable'],
        author = map['author'],
        collectionName = map['name']
                .toString()
                .toLowerCase()
                .toUpperCase()
                .toLowerCase()
                .replaceAll(" ", "_") +
            "_" +
            map['author'] +
            (map['searchable'] ? "_0" : "_1") {
    updateScore(votes);
  }

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Record.fromInitializer(String name, List<int> votes,
      File imageFileToBeUploaded, bool searchable, String author)
      : assert(votes.length == 10),
        assert(name.length > 3 && name.length <= 45),
        name = name,
        votes = votes,
        imageFileToBeUploaded = imageFileToBeUploaded,
        searchable = searchable,
        uploaded = false,
        image = null,
        reference = null,
        author = author,
        collectionName = name
                .toString()
                .toLowerCase()
                .toUpperCase()
                .toLowerCase()
                .replaceAll(" ", "_") +
            "_" +
            author +
            (searchable ? "_0" : "_1") {
    updateScore(votes);
    imageURL = "";
  }

  void updateScore(List<int> _votes) {
    votes = _votes;
    added = votes.reduce((a, b) => a + b);
    totalvotes = votes.reduce((a, b) => a + b) - votes[0];
    unweightedScore = votes
        .fold(IDPair(0, 0),
            (p, val) => IDPair(p.a + 1, p.b + p.a * val / totalvotes))
        .b;
  }

  //Image.file(File(image), width: 600.0, height: 290.0);
  Future<bool> loadImageFromFirebase() async {
    debugPrint("calling loadimage");
    //comment out the next two lines to 'prove' the next time that you run
    //the code to prove that it was downloaded and saved to your device
    if (image == null) {
      //var url =
      //    "https://firebasestorage.googleapis.com/v0/b/mooddex-b9ca6.appspot.com/o/images%2Fchiropractic_bone_cracking.jpg?alt=media&token=80c3ade8-e074-418e-a769-d2bf19b4b244";

      Directory documentDirectory = await getApplicationDocumentsDirectory();
      String firstPath = documentDirectory.path + "/images";
      String filePathAndName =
          documentDirectory.path + '/images/' + collectionName + '.jpg';

      //comment out the next three lines to 'prove' the next time that you run
      // the code to prove that it was downloaded and saved to your device
      await Directory(firstPath).create(recursive: true);
      File file2 = new File(filePathAndName);
      if (!(await file2.exists())) {
        var response = await get(imageURL);
        debugPrint(
            "loaded image with status code " + response.statusCode.toString());
        if (response.statusCode >= 200 && response.statusCode <= 299) {
          file2.writeAsBytesSync(response.bodyBytes);
        } else {
          return false;
        }
      }
      image = filePathAndName;
      return true;
    }
    return false;
  }

  Future<void> _uploadImage() async {
    String extension =
        basename(imageFileToBeUploaded.path).split('.').last.toLowerCase();

    debugPrint('the base name is: ' + extension);

    if (extension != "jpg" && extension != "jpeg" && extension != "png") {
      debugPrint('unknown basename: ' + extension);
      return "";
    }

    FirebaseStorage storage = FirebaseStorage.instance;

    StorageReference ref =
        storage.ref().child("images").child(collectionName + "." + extension);
    StorageUploadTask uploadTask = ref.putFile(imageFileToBeUploaded);

    String dowurl = await (await uploadTask.onComplete).ref.getDownloadURL();
    imageURL = dowurl;
  }

  Future<void> publish() async {
    if (uploaded == true) return;

    FirebaseUser user = globalState.getUser();
    if (user == null || user.uid != author)
      return;
    else {
      List<String> searchWords = name
          .toLowerCase()
          .toUpperCase()
          .toLowerCase()
          .split(" ")
          .where((i) => (i.length > 2 && !stopwords.contains(i)))
          .toList();
      List<String> searchTerms = [];
      for (int i = 0; i < searchWords.length; ++i) {
        for (int j = 3; j <= searchWords[i].length; ++j) {
          searchTerms.add(searchWords[i].substring(0, j));
        }
      }

      DocumentReference _reference =
          Firestore.instance.collection('moods').document(collectionName);
      reference = _reference;

      DocumentSnapshot ds = await _reference.get().catchError((onError) {
        debugPrint('Seems to be offline.');
        return;
      });
      if (ds.exists) {
        uploaded = true;
        return;
      } else {
        //first upload the image, then upload the firestore instance.
        await _uploadImage().then((onValue) async {
          if (imageURL.length > 0) {
            await _reference.setData({
              'name': name,
              'search_terms': searchTerms,
              'votes_0': 0,
              'votes_1': 0,
              'votes_2': 0,
              'votes_3': 0,
              'votes_4': 0,
              'votes_5': 0,
              'votes_6': 0,
              'votes_7': 0,
              'votes_8': 0,
              'votes_9': 0,
              'votes_10': 0,
              'image_ref': imageURL,
              'searchable': searchable,
              'author': author,
            }).then((onValue) {
              uploaded = true;
            }).catchError((onError) {});
          }
        });
      }
    }
  }

  @override
  String toString() => "Record<$name:$added:$votes>";
}
