import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import 'package:cross_file/cross_file.dart';

import 'package:image/image.dart' as imagelib;

import 'package:http/http.dart' show get;
import 'package:path_provider/path_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'globalState.dart';
import 'stopwords.dart';

/*
enum MoodType {
  moods(0,"Moods"),
  anime(1,"Anime"),
  all(9223372036854775807,"All");
  final int value;
  final String name;
  const MoodType(this.value, this.name);
};*/

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
  final String link;
  final int type;

  List<int> votes;
  int totalvotes;
  int added;
  XFile imageFileToBeUploaded; //used when uploading a record
  String imageURL;
  String image; //local location of images for non-web
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
        assert(map['link'] != null),
        assert(map['type'] != null),
        name = map['name'],
        added = 0,
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
            (map['searchable'] ? "_0" : "_1"),
        link = map['link'],
        type = map['type'] {
    updateScore(votes);
  }

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  Record.fromInitializer(
      {String name,
      List<int> votes,
      XFile imageFileToBeUploaded,
      bool searchable,
      String author,
      String link,
      int type})
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
            (searchable ? "_0" : "_1"),
        link = link,
        type = type {
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

      //String filePathAndName = 'images/' + collectionName + '.jpg';
      if (!kIsWeb) {
        Directory documentDirectory = await getApplicationDocumentsDirectory();
        String firstPath = documentDirectory.path + "/images";
        //comment out the next three lines to 'prove' the next time that you run
        // the code to prove that it was downloaded and saved to your device
        await Directory(firstPath).create(recursive: true);
        String filePathAndName =
            documentDirectory.path + '/images/' + collectionName + '.jpg';

        File file2 = new File(filePathAndName);
        if (!(await file2.exists())) {
          var response = await get(Uri.parse(imageURL));
          debugPrint("loaded image with status code " +
              response.statusCode.toString());
          if (response.statusCode >= 200 && response.statusCode <= 299) {
            file2.writeAsBytesSync(response.bodyBytes);
          } else {
            return false;
          }
        }
        image = filePathAndName;
        return true;
      } else {
        image = imageURL; // to make sure it's not null
        return true;
      }
      return false;
    }
  }

  Future<List<int>> readFileBytes(String path, int len) async {
    final File file = File(path);
    RandomAccessFile fileOpen = await file.open(mode: FileMode.read);

    int count = 0;
    List<int> bytes = [];
    int byte;

    while (byte != -1 && count < len) {
      byte = fileOpen.readByteSync();
      bytes.add(byte);
      count++;
    }

    await fileOpen.close();
    return bytes;
  }

  Future<String> _uploadImage() async {
    //old way of doing it
    String extension =
        basename(imageFileToBeUploaded.path).split('.').last.toLowerCase();

    /*
    debugPrint('the base name is: ' +
        basename(imageFileToBeUploaded.path) +
        ' with path ' +
        imageFileToBeUploaded.path);
    */
    //imageFileToBeUploaded.mimeType;

    List<int> byt = await imageFileToBeUploaded.readAsBytes();
    var image = imagelib.decodeImage(byt);
    if (image == null) return "";
    var jpg = imagelib.encodeJpg(image, quality: 80);

    if (jpg == null) return "";

    // https://pub.dev/packages/firebase_storage/example
    firebase_storage.FirebaseStorage storage =
        firebase_storage.FirebaseStorage.instance;
    firebase_storage.Reference refbasic = storage.ref();
    firebase_storage.Reference ref = storage
        .ref()
        .child("images")
        .child(collectionName + ".jpg"); // + extension);

    final metadata =
        firebase_storage.SettableMetadata(contentType: 'image/jpeg');

    debugPrint("so far so good");
    firebase_storage.UploadTask uploadTask = ref.putData(jpg, metadata);
    await uploadTask.then((res) {
      return res.ref.getDownloadURL().then((dowurl) {
        debugPrint("finished uploading image ref: " + dowurl);
        this.imageURL = dowurl;
        return dowurl;
      });
    }).catchError((onError) {
      return "";
    });
    return this.imageURL;
  }

  Future<void> publish() async {
    if (uploaded == true) return;
    User user = globalState.getUser();
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
      searchWords.add(link
          .toLowerCase()
          .toUpperCase()
          .toLowerCase()); //add the link to search terms
      List<String> searchTerms = [];
      for (int i = 0; i < searchWords.length; ++i) {
        for (int j = 3; j <= searchWords[i].length; ++j) {
          searchTerms.add(searchWords[i].substring(0, j));
        }
      }

      DocumentReference _reference =
          FirebaseFirestore.instance.collection('moods').doc(collectionName);
      reference = _reference;

      DocumentSnapshot ds = await _reference.get().catchError((onError) {
        debugPrint('Seems to be offline.');
        //return;
      });

      print("after error");
      if (ds.exists) {
        uploaded = true;
        print("already uploaded");
        return;
      } else {
        print("uploading the image");
        //first upload the image, then upload the firestore instance.
        await _uploadImage().then((onValue) async {
          debugPrint("ok so waited and imageURL is " +
              imageURL +
              " and onvalue " +
              onValue);
          if (imageURL.length > 0) {
            debugPrint("time to upload " + author);

            await _reference.set({
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
              'link': link,
              'location': "",
              'rnd': (new Random()).nextDouble(),
              'ts': FieldValue.serverTimestamp(),
              'type': 0 // mood
            }).then((onValue) {
              debugPrint("final set data");
              uploaded = true;
            }).catchError((onError) {
              debugPrint("error happened: " + onError.toString());
            });
          }
        });
      }
    }
  }

  static String categoryType(int type) {
    if (type == 0)
      return "Moods";
    else if (type == 1)
      return "Anime";
    else if (type == 9223372036854775807)
      return "All";
    else
      return "Unknown";
  }

  String getCategoryType() {
    return Record.categoryType(type);
  }

  @override
  String toString() => "Record<$name:$added:$votes>";
}
