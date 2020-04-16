import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'guide.dart';
import 'record.dart';

class RecordUser {
  final String collectionName;
  final String name;
  final DocumentReference reference;
  final String imageURL;

  String image;

  int category;
  int rating;
  bool hasGuide;
  String guideText;

  RecordUser(String cn, String na, DocumentReference dr, String im, int ra,
      int ca, String gu)
      : collectionName = cn,
        name = na,
        rating = ra,
        reference = dr,
        imageURL = im,
        category = ca,
        guideText = gu;

  RecordUser.fromMap(Map<String, dynamic> map)
      : assert(map["cn"] != null),
        assert(map["na"] != null),
        assert(map["dr"] != null),
        assert(map["im"] != null),
        assert(map["ra"] != null),
        assert(map["ca"] != null),
        assert(map["gu"] != null),
        collectionName = map["cn"],
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

  Future<void> registerUser(
      FirebaseUser user, String username, String email) async {
    DocumentSnapshot ds =
        await Firestore.instance.collection("users").document(user.uid).get();
    if (ds.exists) {
      await Firestore.instance
          .collection("users")
          .document(user.uid)
          .updateData({
        "uid": user.uid,
        "username": username,
        "email": email,
        "globalState": FieldValue.increment(1),
      });
    } else {
      await Firestore.instance.collection("users").document(user.uid).setData({
        "uid": user.uid,
        "username": username,
        "email": email,
        "globalState": 0,
      });
    }
    return;
  }

  Future<bool> setUser(FirebaseUser newUser) async {
    user = newUser;
    userReference =
        Firestore.instance.collection("users").document(newUser.uid);

    DocumentSnapshot ds = await userReference.get().catchError((onError) {
      return false;
    });

    assert(ds.data["globalState"] != null);

    globalStateIndex = ds.data["globalState"];
    if (ds.data["username"] != null) userName = ds.data["username"];

    QuerySnapshot snap = await userReference
        .collection("mymoods")
        .limit(10000)
        .getDocuments()
        .catchError((onError) {
      return false;
    });
    List<DocumentSnapshot> snaps = snap.documents;
    for (int i = 0; i < snaps.length; ++i) {
      RecordUser userRecord = RecordUser.fromSnapshot(snaps[i]);
      userRecords[userRecord.collectionName] = userRecord;
    }

    return true;
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
          .get(userReference.collection("mymoods").document(r.collectionName));
      if (ds.exists) {
        //check what the score is and modify it
        assert(ds.data["cn"] != null);
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
            userReference.collection("mymoods").document(r.collectionName), {
          "ra": rating,
          "ca": category,
        });
      } else {
        await transaction.set(
            userReference.collection("mymoods").document(r.collectionName), {
          "na": r.name,
          "cn": r.collectionName,
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

      RecordUser ru = RecordUser(r.collectionName, r.name, r.reference,
          r.imageURL, rating, category, guideText);
      userRecords[r.collectionName] = ru;

      for (int i = 0; i < updateTheseWidgetsOnUpdate.length; ++i) {
        try {
          updateTheseWidgetsOnUpdate[i]();
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

    WriteBatch batch = Firestore.instance.batch();
    batch.setData(r.reference.collection("guides").document(user.uid), {
      "au": userName,
      "uid": user.uid,
      "gu": guideText,
      "ra": recordUser.rating,
      "ca": recordUser.category,
      "hf": 0,
      "ts": FieldValue.serverTimestamp(),
    });
    batch.updateData(
        userReference.collection("mymoods").document(r.collectionName), {
      "gu": guideText,
    });

    batch.updateData(userReference, {
      "globalState": FieldValue.increment(1),
    });

    await batch.commit().then((value) {
      globalStateIndex += 1;

      userRecords[r.collectionName] = recordUser;

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
        r.reference.collection("guides").document(guide.uid);
    DocumentReference uservoteonguide = userReference
        .collection("myguidevotes")
        .document(r.collectionName)
        .collection("comments")
        .document(guide.uid);
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
