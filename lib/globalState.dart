import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import 'record.dart';

class RecordUser {
  String searchName;
  int category;
  int rating;
  bool hasGuide;
  String guideText;

  RecordUser(String na, int ra, int ca, String gt)
      : searchName = na,
        rating = ra,
        category = ca,
        guideText = gt;

  RecordUser.fromMap(Map<String, dynamic> map)
      : assert(map["na"] != null),
        assert(map["ra"] != null),
        assert(map["ca"] != null),
        assert(map["gt"] != null),
        searchName = map["na"],
        category = map["ca"],
        rating = map["ra"],
        guideText = map["gt"];

  RecordUser.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data);
}

class GlobalState {
  FirebaseUser _user;
  DocumentReference _userReference;
  int globalStateIndex; //starts at 0 and will be increased atomically step-by-step on every update.
  Map<String, RecordUser> userRecords;

  GlobalState()
      : _user = null,
        userRecords = Map<String, RecordUser>(),
        globalStateIndex = -1;
  Future<void> setUser(FirebaseUser user) async {
    debugPrint("Bonjorno");
    _user = user;
    _userReference = Firestore.instance.collection("users").document(user.uid);

    if (globalStateIndex == -1) {
      debugPrint("Bonjornoko");

      DocumentSnapshot ds = await _userReference.get();
      debugPrint("ds get");

      assert(ds.data["globalState"] != null);
      globalStateIndex = ds.data["globalState"];

      QuerySnapshot snap = await _userReference
          .collection("mymoods")
          .limit(10000)
          .getDocuments();
      List<DocumentSnapshot> snaps = snap.documents;
      for (int i = 0; i < snaps.length; ++i) {
        RecordUser userRecord = RecordUser(snaps[i].data["na"],
            snaps[i].data["ra"], snaps[i].data["ca"], snaps[i].data["gu"]);
        userRecords[userRecord.searchName] = userRecord;
      }
      debugPrint("done getting");
    }

    return;
  }

  FirebaseUser getUser() {
    return _user;
  }

  Future<Record> addRating(Record r, int rating, int category) async {
    assert(rating >= 0 && rating <= 10);
    assert(category >= 0 && category <= 2);
    int previousRating = -1;
    String guideText = "";
    await Firestore.instance.runTransaction((transaction) async {
      DocumentSnapshot ds = await transaction
          .get(_userReference.collection("mymoods").document(r.searchName));
      if (ds.exists) {
        //check what the score is and modify it
        assert(ds.data["ra"] != null);
        assert(ds.data["ca"] != null);
        assert(ds.data["gu"] != null);
        guideText = ds.data["gu"];
        previousRating = ds.data["ra"];
        if (guideText.length > 0) {
          await transaction
              .update(r.reference.collection("guides").document(_user.uid), {
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
            _userReference.collection("mymoods").document(r.searchName), {
          "ra": rating,
          "ca": category,
        });
      } else {
        await transaction
            .set(_userReference.collection("mymoods").document(r.searchName), {
          "na": r.searchName,
          "ra": rating,
          "ca": category,
          "gu": "",
        });

        await transaction.update(r.reference, {
          "votes_" + rating.toString(): FieldValue.increment(1),
        });
      }
      await transaction.update(_userReference, {
        "globalState": FieldValue.increment(1),
      });
    }).then((res) {
      globalStateIndex += 1;

      List<int> votes = r.votes;
      if (previousRating >= 0) votes[previousRating]--;
      votes[rating]++;

      r.updateScore(votes);

      RecordUser ru = RecordUser(r.searchName, rating, category, guideText);
      userRecords[r.searchName] = ru;
    });

    return r;
  }

  void addGuide(Record r, String guideText) async {
    RecordUser recordUser;
    if (userRecords.containsKey(r.searchName)) {
      recordUser = userRecords[r.searchName];
    } else {
      recordUser = RecordUser(r.searchName, 0, 0, guideText);
    }
    WriteBatch batch = Firestore.instance.batch();
    batch.setData(r.reference.collection("guides").document(_user.uid), {
      "au": _user.uid,
      "gu": guideText,
      "ra": recordUser.rating,
      "ca": recordUser.category,
      "ts": FieldValue.serverTimestamp(),
    });
    batch.updateData(
        _userReference.collection("mymoods").document(r.searchName), {
      "gu": guideText,
    });

    batch.updateData(_userReference, {
      "globalState": FieldValue.increment(1),
    });

    await batch.commit().then((value) {
      globalStateIndex += 1;
      if (userRecords.containsKey(r.searchName)) {
        userRecords[r.searchName] = recordUser;
      } else {
        userRecords[r.searchName] = recordUser;
      }
    });
  }
}

GlobalState globalState = GlobalState(); //initialized global state
