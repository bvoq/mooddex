import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import 'guide.dart';
import 'record.dart';

class RecordUser {
  final String searchName;
  final String name;
  final DocumentReference reference;
  final String imageURL;

  String image;

  int category;
  int rating;
  bool hasGuide;
  String guideText;

  RecordUser(String sn, String na, DocumentReference dr, String im, int ra,
      int ca, String gu)
      : searchName = sn,
        name = na,
        rating = ra,
        reference = dr,
        imageURL = im,
        category = ca,
        guideText = gu;

  RecordUser.fromMap(Map<String, dynamic> map)
      : assert(map["sn"] != null),
        assert(map["na"] != null),
        assert(map["dr"] != null),
        assert(map["im"] != null),
        assert(map["ra"] != null),
        assert(map["ca"] != null),
        assert(map["gu"] != null),
        searchName = map["sn"],
        name = map["na"],
        reference = map["dr"],
        imageURL = map["im"],
        category = map["ca"],
        rating = map["ra"],
        guideText = map["gu"];

  RecordUser.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data);
}

class GlobalState {
  FirebaseUser user;
  DocumentReference userReference;
  String userName;

  int globalStateIndex; //starts at 0 and will be increased atomically step-by-step on every update.
  Map<String, RecordUser> userRecords;
  List<Function> updateTheseWidgetsOnUpdate;

  GlobalState()
      : user = null,
        userRecords = Map<String, RecordUser>(),
        globalStateIndex = -1,
        updateTheseWidgetsOnUpdate = [],
        userName = "";

  void addUpdateFunction(Function toCall) {
    updateTheseWidgetsOnUpdate.add(toCall);
  }

  Future<void> setUser(FirebaseUser newUser) async {
    user = newUser;
    userReference =
        Firestore.instance.collection("users").document(newUser.uid);

    DocumentSnapshot ds = await userReference.get();

    assert(ds.data["globalState"] != null);

    globalStateIndex = ds.data["globalState"];
    if (ds.data["username"] != null) userName = ds.data["username"];

    QuerySnapshot snap =
        await userReference.collection("mymoods").limit(10000).getDocuments();
    List<DocumentSnapshot> snaps = snap.documents;
    for (int i = 0; i < snaps.length; ++i) {
      RecordUser userRecord = RecordUser.fromSnapshot(snaps[i]);
      userRecords[userRecord.searchName] = userRecord;
    }

    return;
  }

  FirebaseUser getUser() {
    return user;
  }

  Future<Record> addRating(Record r, int rating, int category) async {
    assert(rating >= 0 && rating <= 10);
    assert(category >= 0 && category <= 2);
    int previousRating = -1;
    String guideText = "";
    await Firestore.instance.runTransaction((transaction) async {
      DocumentSnapshot ds = await transaction
          .get(userReference.collection("mymoods").document(r.searchName));
      if (ds.exists) {
        //check what the score is and modify it
        assert(ds.data["sn"] != null);
        assert(ds.data["na"] != null);
        assert(ds.data["ra"] != null);
        assert(ds.data["im"] != null);
        assert(ds.data["ca"] != null);
        assert(ds.data["gu"] != null);
        guideText = ds.data["gu"];
        previousRating = ds.data["ra"];
        if (guideText.length > 0) {
          await transaction
              .update(r.reference.collection("guides").document(user.uid), {
            "ra": rating,
            "ca": category,
          });
        }

        if (rating != previousRating) {
          //got to change the votes correctly.
          await transaction.update(r.reference, {
            "votes_" + previousRating.toString(): FieldValue.increment(-1),
          });
          await transaction.update(r.reference, {
            "votes_" + rating.toString(): FieldValue.increment(1),
          });
        }
        await transaction.update(
            userReference.collection("mymoods").document(r.searchName), {
          "ra": rating,
          "ca": category,
        });
      } else {
        await transaction
            .set(userReference.collection("mymoods").document(r.searchName), {
          "na": r.name,
          "sn": r.searchName,
          "dr": r.reference,
          "im": r.imageURL,
          "gu": "",
          "ra": rating,
          "ca": category,
        });

        await transaction.update(r.reference, {
          "votes_" + rating.toString(): FieldValue.increment(1),
        });
      }
      await transaction.update(userReference, {
        "globalState": FieldValue.increment(1),
      });
    }).then((res) {
      globalStateIndex += 1;

      List<int> votes = r.votes;
      if (previousRating >= 0) votes[previousRating]--;
      votes[rating]++;

      r.updateScore(votes);

      RecordUser ru = RecordUser(r.searchName, r.name, r.reference, r.imageURL,
          rating, category, guideText);
      userRecords[r.searchName] = ru;

      for (int i = 0; i < updateTheseWidgetsOnUpdate.length; ++i) {
        try {
          updateTheseWidgetsOnUpdate[i]();
        } catch (e) {}
      }
    });

    return r;
  }

  Future<void> addGuide(Record r, String guideText) async {
    RecordUser recordUser;
    if (userRecords.containsKey(r.searchName)) {
      recordUser = userRecords[r.searchName];
      recordUser.guideText = guideText;
    } else {
      recordUser = RecordUser(
          r.searchName, r.name, r.reference, r.imageURL, 0, 0, guideText);
    }
    WriteBatch batch = Firestore.instance.batch();
    batch.setData(r.reference.collection("guides").document(user.uid), {
      "uid": user.uid,
      "gu": guideText,
      "ra": recordUser.rating,
      "ca": recordUser.category,
      "hf": 0,
      "ts": FieldValue.serverTimestamp(),
    });
    batch.updateData(
        userReference.collection("mymoods").document(r.searchName), {
      "gu": guideText,
    });

    batch.updateData(userReference, {
      "globalState": FieldValue.increment(1),
    });

    await batch.commit().then((value) {
      globalStateIndex += 1;
      if (userRecords.containsKey(r.searchName)) {
        userRecords[r.searchName] = recordUser;
      } else {
        userRecords[r.searchName] = recordUser;
      }

      for (int i = 0; i < updateTheseWidgetsOnUpdate.length; ++i) {
        try {
          updateTheseWidgetsOnUpdate[i]();
        } catch (e) {}
      }
    });
    return;
  }

  void rateGuide(Record r, Guide guide, int vote) async {
    assert(vote == 1 || vote == -1 || vote == 0);
    DocumentReference guidereference =
        r.reference.collection("guides").document(guide.author_uid);
    DocumentReference uservoteonguide = userReference
        .collection("myguidevotes")
        .document(r.searchName)
        .collection("comments")
        .document(guide.author_uid);
    await Firestore.instance.runTransaction((transaction) async {
      DocumentSnapshot ds = await transaction.get(uservoteonguide);
      if (ds.exists && ds.data["hf"] != null && ds.data["hf"] != 0) {
        if (ds.data["hf"] == 0 ||
            (ds.data["hf"] == 1 && vote == -1) ||
            (ds.data["hf"] == -1 && vote == 1)) {
          assert(ds.data["hf"] != null);
          transaction.update(guidereference, {
            "hf": ds.data["hf"] == 0
                ? FieldValue.increment(vote)
                : FieldValue.increment(2 * vote)
          });

          await transaction.update(uservoteonguide, {
            "hf": vote,
          });
        }
      } else {
        transaction.update(guidereference, {"hf": FieldValue.increment(vote)});
        transaction.set(uservoteonguide, {
          "hf": vote,
        });
      }
    });
  }
}

GlobalState globalState = GlobalState(); //initialized global state
