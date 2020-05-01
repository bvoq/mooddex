import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';

import 'moodDetail.dart';
import 'moodAdd.dart';
import 'record.dart';
import 'stopwords.dart';

/*
class MoodSearchCupertino extends CupertinoSearchBar {
  @override
  // 
  get onSubmitted => super.onSubmitted;
}*/
/*
CupertinoSearchBar MoodSearchCupertino() {
  return CupertinoSearchBar(key: UniqueKey(), TextEditingController controller, FocusNode focusNode, VoidCallback onCancel, ValueChanged<String> onChanged, ValueChanged<String> onSubmitted, bool autoFocus: false, Animation<double> animation, VoidCallback onClear, bool enabled: true, bool autoCorrect: true);
}*/

Widget _buildList(
    BuildContext context, List<DocumentSnapshot> snapshot, String query) {
  List<Widget> searchWidgets =
      snapshot.map((data) => _buildListItem(context, data, query)).toList();
  searchWidgets.add(_addNewMood(context, query));
  return ListView(
    padding: const EdgeInsets.only(top: 20.0),
    children: searchWidgets,
  );
}

Widget _addNewMood(BuildContext context, String query) {
  return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).accentColor),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Row(
          children: [
            Expanded(
                child: ListTile(
                    title: Text("Add mood: " + query),
                    leading:
                        Icon(Icons.add, color: Theme.of(context).accentColor),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MoodAdd(query: query),
                        )))),
          ],
        ),
      ));
}

Widget _searchSuggestions(String query) {
  List<String> searchTerms = query
      .toLowerCase()
      .toUpperCase()
      .toLowerCase()
      .split(" ")
      .where((i) => (i.length > 2 && !stopwords.contains(i)))
      .toList();

  debugPrint('calling buildSuggestions with ' + searchTerms.toString());

  if (query.length < 3 || searchTerms.length == 0) {
    String errorMsg = "Search term must be longer than two letters";
    if (query.length >= 3)
      errorMsg = "Search term must contain substantial words.";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
          child: Text(
            errorMsg,
          ),
        )
      ],
    );
  } else {
    searchTerms.add(query
        .toLowerCase()
        .toUpperCase()
        .toLowerCase()); // add full query for special search strings
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('moods')
          .where('searchable', isEqualTo: true)
          .where('search_terms', arrayContainsAny: searchTerms)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.documents, query);
      },
    );
  }
}

Widget _buildListItem(
    BuildContext context, DocumentSnapshot data, String query) {
  //final record = Record.fromMap(data); // where Map data
  Record record = Record.fromSnapshot(data);
  return Padding(
    key: ValueKey(record.name),
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ListTile(
          title: Text(record.name),
          trailing: Container(
            width: 40,
            child: Row(
              children: [
                Icon(Icons.people),
                Text(record.added.toString()),
              ],
            ),
          ),
          onTap: () async {
            //record.loadImageFromFirebase().then((void v) =>
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoodDetail(initialRecord: record),
                ));
          }
          // Navigator.of(context).push(record.findValue), //print(record),
          ),
    ),
  );
}

class MoodSearchMaterial extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) => [];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      );

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _searchSuggestions(query);
  }
}

//Taken from: https://fluttertutorial.in/ios-searchbar-in-flutter/
class IOSSearchBar extends AnimatedWidget {
  IOSSearchBar({
    Key key,
    @required Animation<double> animation,
    @required this.controller,
    @required this.focusNode,
    this.onCancel,
    this.onClear,
    this.onSubmit,
    this.onUpdate,
  })  : assert(controller != null),
        assert(focusNode != null),
        super(key: key, listenable: animation);

  /// The text editing controller to control the search field
  final TextEditingController controller;

  /// The focus node needed to manually unfocus on clear/cancel
  final FocusNode focusNode;

  /// The function to call when the "Cancel" button is pressed
  final Function onCancel;

  /// The function to call when the "Clear" button is pressed
  final Function onClear;

  /// The function to call when the text is updated
  final Function(String) onUpdate;

  /// The function to call when the text field is submitted
  final Function(String) onSubmit;
  static final _opacityTween = new Tween(begin: 1.0, end: 0.0);
  static final _paddingTween = new Tween(begin: 0.0, end: 60.0);
  static final _kFontSize = 13.0;
  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    return Material(
        child: new Row(children: <Widget>[
      new Expanded(
          child: new Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              decoration: new BoxDecoration(
                color: CupertinoColors.white,
                border:
                    new Border.all(width: 0.0, color: CupertinoColors.white),
                borderRadius: new BorderRadius.circular(10.0),
              ),
              child: Stack(alignment: Alignment.centerLeft, children: <Widget>[
                Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                          padding:
                              const EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 1.0),
                          child: Icon(
                            CupertinoIcons.search,
                            color: CupertinoColors.inactiveGray,
                            size: _kFontSize + 2.0,
                          ))
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: TextField(
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(10.0),
                                hintText: 'Search',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.transparent),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent))),
                            controller: controller,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15.0,
                            ),
                            autocorrect: false,
                            focusNode: focusNode,
                            onChanged: onUpdate,
                            onSubmitted: onSubmit,
                            cursorColor: CupertinoColors.black,
                          ),
                        ),
                      ),
                      CupertinoButton(
                          minSize: 10.0,
                          padding: const EdgeInsets.all(1.0),
                          borderRadius: BorderRadius.circular(30.0),
                          color: CupertinoColors.inactiveGray.withOpacity(
                            1.0 - _opacityTween.evaluate(animation),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 12.0,
                            color: CupertinoColors.white,
                          ),
                          onPressed: () {
                            if (animation.isDismissed)
                              return;
                            else
                              onClear();
                          })
                    ])
              ]))),
      SizedBox(
          width: _paddingTween.evaluate(animation),
          child: CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              onPressed: onCancel,
              child: Text('Cancel',
                  softWrap: false,
                  style: TextStyle(
                    inherit: false,
                    color: CupertinoColors.black,
                    fontSize: _kFontSize,
                  ))))
    ]));
  }
}

class MoodSearchCupertino extends StatefulWidget {
  MoodSearchCupertino();
  createState() => new MoodSearchCupertinoState();
}

class MoodSearchCupertinoState extends State<MoodSearchCupertino>
    with SingleTickerProviderStateMixin {
  MoodSearchCupertinoState();
  TextEditingController _searchTextController = new TextEditingController();
  FocusNode _searchFocusNode = new FocusNode();
  Animation _animation;
  AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _animationController = new AnimationController(
      duration: new Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = new CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    _searchFocusNode.addListener(() {
      if (!_animationController.isAnimating) {
        _animationController.forward();
      }
    });
  }

  void _cancelSearch() {
    _searchTextController.clear();
    _searchFocusNode.unfocus();
    _animationController.reverse();
  }

  void _clearSearch() {
    _searchTextController.clear();
  }

  @override
  Widget build(BuildContext context) {
    _searchTextController.addListener(() => setState(() {}));
    return new Scaffold(
        body: new CupertinoPageScaffold(
      navigationBar: new CupertinoNavigationBar(
        middle: new IOSSearchBar(
          controller: _searchTextController,
          focusNode: _searchFocusNode,
          animation: _animation,
          onCancel: _cancelSearch,
          onClear: _clearSearch,
        ),
      ),
      child: new GestureDetector(
        onTapUp: (TapUpDetails _) {
          _searchFocusNode.unfocus();
          if (_searchTextController.text == '') {
            _animationController.reverse();
          }
        },
        child: _searchSuggestions(
            _searchTextController.text), // Add search body here
      ),
    ));
  }
}
