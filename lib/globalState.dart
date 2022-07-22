import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'guide.dart';
import 'record.dart';

class RecordUser {
  final String collectionName;
  final String name;
  final DocumentReference reference;
  final String imageURL;
  final int type;

  String image;

  int category;
  int rating;
  bool hasGuide;
  String guideText;

  RecordUser(String cn, String na, DocumentReference dr, String im, int ra,
      int ca, int ty, String gu)
      : collectionName = cn,
        name = na,
        rating = ra,
        reference = dr,
        imageURL = im,
        category = ca,
        type = ty,
        guideText = gu;

  RecordUser.fromMap(Map<String, dynamic> map)
      : assert(map["cn"] != null),
        assert(map["na"] != null),
        assert(map["dr"] != null),
        assert(map["im"] != null),
        assert(map["ra"] != null),
        assert(map["ca"] != null),
        assert(map["gu"] != null),
        type = map.containsKey("ty")
            ? map["ty"]
            : 0, //old accounts don't have type info.
        collectionName = map["cn"],
        name = map["na"],
        reference = map["dr"],
        imageURL = map["im"],
        category = map["ca"],
        rating = map["ra"],
        guideText = map["gu"];

  RecordUser.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data());
}

class GlobalState {
  User user;
  DocumentReference userReference;
  String userName;
  String topGuideComment = "";

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

  Future<void> registerUser(User user, String username, String email) async {
    //DocumentSnapshot ds =
    //    await Firestore.instance.collection("users").document(user.uid).get();

    await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "username": username,
      "email": email,
      "globalState": 0,
    });

    return;
  }

  String getTopGuideComment() {
    return topGuideComment;
  }

  void setTopGuideComment(String str) {
    topGuideComment = str;
  }

  Future<bool> setUser(User newUser) async {
    user = newUser;
    userReference =
        FirebaseFirestore.instance.collection("users").doc(newUser.uid);
    debugPrint("wait for user reference");
    DocumentSnapshot ds = await userReference.get().catchError((onError) {
      if (onError.code == "Error 7") FirebaseAuth.instance.signOut();
      debugPrint("error code: " + onError.code);
      return false;
    });
    if (!ds.exists) {
      FirebaseAuth.instance.signOut();
      return false;
    }

    assert(ds.get("globalState") != null);
    globalStateIndex = ds.get("globalState");
    if (ds.get("username") != null) userName = ds.get("username");

    QuerySnapshot snap = await userReference
        .collection("mymoods")
        .limit(10000)
        .get()
        .catchError((onError) {
      debugPrint("error118 on: " + onError.toString());
      return false;
    }).catchError((error) {
      FirebaseAuth.instance.signOut();
    });

    List<DocumentSnapshot> snaps = snap.docs;
    for (int i = 0; i < snaps.length; ++i) {
      RecordUser userRecord = RecordUser.fromSnapshot(snaps[i]);
      userRecords[userRecord.collectionName] = userRecord;
    }

    return true;
  }

  User getUser() {
    return user;
  }

  Future<void> removeRating(Record r) async {
    int previousRating = -1;
    String guideText = "";
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot ds = await transaction
          .get(userReference.collection("mymoods").doc(r.collectionName));
      if (ds.exists) {
        previousRating = ds.get("ra");
        guideText = ds.get("gu");
        if (guideText.length > 0) {
          await transaction
              .update(r.reference.collection("guides").doc(user.uid), {
            "ra": 0,
            "ca": 0,
          });
        }
        await transaction.update(r.reference, {
          "votes_" + previousRating.toString(): FieldValue.increment(-1),
        });
      }
      await transaction
          .delete(userReference.collection("mymoods").doc(r.collectionName));

      await transaction.update(userReference, {
        "globalState": FieldValue.increment(1),
      });
    }).then((vo) {
      userRecords.remove(r.collectionName);
      r.votes[previousRating]--;
      r.updateScore(r.votes);

      for (int i = 0; i < updateTheseWidgetsOnUpdate.length; ++i) {
        try {
          updateTheseWidgetsOnUpdate[i](r);
        } catch (e) {}
      }
    });
    return;
  }

  Future<Record> addRating(Record r, int rating, int category) async {
    assert(rating >= 0 && rating <= 10);
    assert(category >= 0 && category <= 2);
    int previousRating = -1;
    String guideText = "";
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot ds = await transaction
          .get(userReference.collection("mymoods").doc(r.collectionName));
      if (ds.exists) {
        //check what the score is and modify it
        assert(ds.get("cn") != null);
        assert(ds.get("na") != null);
        assert(ds.get("ra") != null);
        assert(ds.get("im") != null);
        assert(ds.get("ca") != null);
        assert(ds.get("gu") != null);
        /*int type = ds.get("ty") != null
            ? ds.get("ty")
            : 0;*/ //update old users automatically
        guideText = ds.get("gu");
        previousRating = ds.get("ra");
        if (guideText.length > 0) {
          await transaction
              .update(r.reference.collection("guides").doc(user.uid), {
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
        await transaction
            .update(userReference.collection("mymoods").doc(r.collectionName), {
          "ra": rating,
          "ca": category,
        });
      } else {
        await transaction
            .set(userReference.collection("mymoods").doc(r.collectionName), {
          "na": r.name,
          "cn": r.collectionName,
          "dr": r.reference,
          "im": r.imageURL,
          "gu": "",
          "ra": rating,
          "ca": category,
          "ty": r.type
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

      RecordUser ru = RecordUser(r.collectionName, r.name, r.reference,
          r.imageURL, rating, category, r.type, guideText);
      userRecords[r.collectionName] = ru;

      for (int i = 0; i < updateTheseWidgetsOnUpdate.length; ++i) {
        try {
          updateTheseWidgetsOnUpdate[i](r);
        } catch (e) {}
      }
    });

    return r;
  }

  Future<void> addGuide(Record r, String guideText) async {
    if (!userRecords.containsKey(r.collectionName)) {
      await addRating(r, 0, 0);
    }
    assert(userRecords.containsKey(r.collectionName));
    RecordUser recordUser = userRecords[r.collectionName];
    recordUser.guideText = guideText;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    batch.set(r.reference.collection("guides").doc(user.uid), {
      "au": userName,
      "uid": user.uid,
      "gu": guideText,
      "ra": recordUser.rating,
      "ca": recordUser.category,
      "hf": 0,
      "ts": FieldValue.serverTimestamp(),
    });
    batch.update(userReference.collection("mymoods").doc(r.collectionName), {
      "gu": guideText,
    });

    batch.update(userReference, {
      "globalState": FieldValue.increment(1),
    });

    await batch.commit().then((value) {
      globalStateIndex += 1;

      userRecords[r.collectionName] = recordUser;

      for (int i = 0; i < updateTheseWidgetsOnUpdate.length; ++i) {
        try {
          updateTheseWidgetsOnUpdate[i](r);
        } catch (e) {}
      }
    });
    return;
  }

  void rateGuide(Record r, Guide guide, int vote) async {
    assert(vote == 1 || vote == -1 || vote == 0);
    DocumentReference guidereference =
        r.reference.collection("guides").doc(guide.uid);
    DocumentReference uservoteonguide = userReference
        .collection("myguidevotes")
        .doc(r.collectionName)
        .collection("comments")
        .doc(guide.uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot ds = await transaction.get(uservoteonguide);
      if (ds.exists && ds.get("hf") != null && ds.get("hf") != 0) {
        if (ds.get("hf") == 0 ||
            (ds.get("hf") == 1 && vote == -1) ||
            (ds.get("hf") == -1 && vote == 1)) {
          assert(ds.get("hf") != null);
          transaction.update(guidereference, {
            "hf": ds.get("hf") == 0
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
