import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
//import 'package:universal_html/html.dart';

import 'moodDetail.dart';
import 'globalState.dart';
import 'record.dart';

import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:tuple/tuple.dart';

class MoodTypes extends StatefulWidget {
  @override
  MoodTypesState createState() => MoodTypesState();
}

class MoodTypesState extends State<MoodTypes> {
  List<Tuple2<int, String>> sortingOrders = [
    Tuple2<int, String>(1, "images/anime.png"),
    Tuple2<int, String>(0, "images/mood.png"),
    Tuple2<int, String>(9223372036854775807, "images/all.png")
  ];

  MoodTypesState() {}

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(children: [
      CupertinoNavigationBar(middle: Text("Mood Types")),
      Expanded(
          child: GridView.count(
        // Create a grid with 2 columns. If you change the scrollDirection to
        // horizontal, this produces 2 rows.
        crossAxisCount: 2,
        // Generate 100 widgets that display their index in the List.
        children: List.generate(sortingOrders.length, (index) {
          return Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MyMoods(moodType: sortingOrders[index].item1),
                      ));
                },
                child: Column(
                  children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.topCenter,
                            child: Image.asset(
                              sortingOrders[index].item2,
                              fit: BoxFit.fitHeight,
                            ))),
                    Container(
                        alignment: Alignment.bottomCenter,
                        margin: EdgeInsets.all(5),
                        child: Text(
                            Record.categoryType(sortingOrders[index].item1),
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                )),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: EdgeInsets.all(15),
          );
          /*
          return Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            //elevation: 5,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage(sortingOrders[index].item2))),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(Record.categoryType(sortingOrders[index].item1),
                    style: TextStyle(fontSize: 25)),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            margin: EdgeInsets.only(
                left: 15.0, right: 15.0, top: 15.0, bottom: 15.0),
          );*/
        }

            /*
           Container(
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Image.asset(sortingOrders[index].item2));
          */
            ),
      ))
    ]));
  }
}

class MyMoods extends StatefulWidget {
  final int moodType;
  MyMoods({Key key, @required this.moodType}) : super(key: key);

  @override
  MyMoodsState createState() => MyMoodsState(moodType);
}

class MyMoodsState extends State<MyMoods> {
  int moodType;
  List<RecordUser> records;
  List<int> sortingOrders = [1, 1, -1];
  int currentSortedIndex;

  MyMoodsState(int _moodType) {
    moodType = _moodType;
    loadMyMoods(2, true);
    globalState.addUpdateFunction((Record record) {
      loadMyMoods(currentSortedIndex, false);
      return;
    });
  }
/*
  @override
  void initState() {
    super.initState();
    initDynamicLinks(context);
  }*/

  void loadMyMoods(int index, bool constructor) {
    assert(index >= 0 && index <= 2);
    if (currentSortedIndex == index)
      sortingOrders[index] = -sortingOrders[index];

    currentSortedIndex = index;
    records = globalState.userRecords.entries
        .where(
            (a) => moodType == 9223372036854775807 || a.value.type == moodType)
        .map((e) => e.value)
        .toList();
    //now sort according to selected criteria.
    records.sort((a, b) {
      if (index == 0) {
        return sortingOrders[index] *
            a.collectionName.compareTo(b.collectionName);
      } else if (index == 1) {
        return sortingOrders[index] * a.category.compareTo(b.category);
      } else if (index == 2) {
        return sortingOrders[index] * a.rating.compareTo(b.rating);
      }
      return 0;
    });

    if (!constructor) setState(() => {}); //call build function again.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: <Widget>[
        CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            /*
            leading: GestureDetector(
                child: Stack(children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.arrow_back, color: Colors.black)),
                  Align(alignment: Alignment.center, child: Text("Mood List"))
                ]),
                onTap: () {
                  Navigator.of(context).pop();
                }),*/
            largeTitle: Row(children: [
              GestureDetector(
                  child: Icon(Icons.arrow_back, color: Colors.black),
                  onTap: () {
                    Navigator.of(context).pop();
                  }),
              Text(Record.categoryType(moodType))
            ])),
        SliverStickyHeader(
          overlapsContent: true,
          header: Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.98),
            child: DataTable(
                sortColumnIndex: currentSortedIndex,
                sortAscending: sortingOrders[currentSortedIndex] >= 0,
                columnSpacing: 0,
                horizontalMargin: 24,
                columns: [
                  DataColumn(
                    label: Container(
                      width:
                          (MediaQuery.of(context).size.width - 5.3 * 24) * 0.59,
                      child: Text("Name"),
                    ),
                    onSort: (columnIndex, sortAscending) =>
                        loadMyMoods(columnIndex, false),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Container(
                      width:
                          (MediaQuery.of(context).size.width - 6 * 24) * 0.27,
                      child: Text("Category"),
                    ),
                    onSort: (columnIndex, sortAscending) =>
                        loadMyMoods(columnIndex, false),
                    numeric: false,
                  ),
                  DataColumn(
                      label: Container(
                        width:
                            (MediaQuery.of(context).size.width - 6 * 24) * 0.20,
                        child: Text("Rating"),
                      ),
                      onSort: (columnIndex, sortAscending) =>
                          loadMyMoods(columnIndex, false),
                      numeric: true),
                ],
                rows: [] /*
            DataRow(
              cells: [
                DataCell(
                  Container(
                    width: MediaQuery.of(context).size.width * 0.33333,
                    child: Text(""),
                  ),
                ),
                DataCell(Text("I do this")),
                DataCell(
                  Text("NaN"),
                ),
              ],
            ),
          ],*/
                ),
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              child: DataTable(
                columnSpacing: 0,
                horizontalMargin: 24,
                dataRowHeight: 48,
                columns: [
                  DataColumn(
                    label: Container(
                      width:
                          (MediaQuery.of(context).size.width - 4.5 * 24) * 0.59,
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width:
                          (MediaQuery.of(context).size.width - 4.5 * 24) * 0.24,
                    ),
                    numeric: false,
                  ),
                  DataColumn(
                      label: Container(
                        width: (MediaQuery.of(context).size.width - 4.5 * 24) *
                            0.17,
                      ),
                      numeric: true),
                ],
                rows: records
                    .map(
                      (recordUser) => DataRow(
                        cells: [
                          DataCell(
                            Container(
                              alignment: Alignment.centerLeft,
                              width: (MediaQuery.of(context).size.width -
                                      4.5 * 24) *
                                  0.59,
                              height: 48,
                              child: Text(recordUser.name),
                            ),
                            onTap: () => tappedOnMood(
                                context, recordUser.collectionName),
                          ),
                          DataCell(
                              Container(
                                alignment: Alignment.centerLeft,
                                width: (MediaQuery.of(context).size.width -
                                        4.5 * 24) *
                                    0.24,
                                height: 48,
                                child: Text(
                                  typeCategoryToName[recordUser.type]
                                          [recordUser.category] ??
                                      "",
                                ),
                              ),
                              onTap: () => tappedOnMood(
                                  context, recordUser.collectionName)),
                          DataCell(
                            Container(
                                alignment: Alignment.centerRight,
                                width: (MediaQuery.of(context).size.width -
                                        4.5 * 24) *
                                    0.17,
                                height: 48,
                                child: Text(recordUser.rating == 0
                                    ? "NaN"
                                    : recordUser.rating.toString())),
                            placeholder: recordUser.rating == 0,
                            onTap: () => tappedOnMood(
                                context, recordUser.collectionName),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    ));
    /*
        CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(largeTitle: Text("Mood Dex")),
                myMoods,
              ],
            )
            
    return SliverStickyHeader(
      overlapsContent: true,
      header: Container(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.98),
        child: DataTable(
            sortColumnIndex: currentSortedIndex,
            sortAscending: sortingOrders[currentSortedIndex] >= 0,
            columnSpacing: 0,
            horizontalMargin: 24,
            columns: [
              DataColumn(
                label: Container(
                  width: (MediaQuery.of(context).size.width - 5.3 * 24) * 0.59,
                  child: Text("Name"),
                ),
                onSort: (columnIndex, sortAscending) =>
                    loadMyMoods(columnIndex, false),
                numeric: false,
              ),
              DataColumn(
                label: Container(
                  width: (MediaQuery.of(context).size.width - 6 * 24) * 0.24,
                  child: Text("Category"),
                ),
                onSort: (columnIndex, sortAscending) =>
                    loadMyMoods(columnIndex, false),
                numeric: false,
              ),
              DataColumn(
                  label: Container(
                    width: (MediaQuery.of(context).size.width - 6 * 24) * 0.17,
                    child: Text("Rating"),
                  ),
                  onSort: (columnIndex, sortAscending) =>
                      loadMyMoods(columnIndex, false),
                  numeric: true),
            ],
            rows: [] /*
            DataRow(
              cells: [
                DataCell(
                  Container(
                    width: MediaQuery.of(context).size.width * 0.33333,
                    child: Text(""),
                  ),
                ),
                DataCell(Text("I do this")),
                DataCell(
                  Text("NaN"),
                ),
              ],
            ),
          ],*/
            ),
      ),
      sliver: SliverToBoxAdapter(
        child: Container(
          child: DataTable(
            columnSpacing: 0,
            horizontalMargin: 24,
            dataRowHeight: 48,
            columns: [
              DataColumn(
                label: Container(
                  width: (MediaQuery.of(context).size.width - 4.5 * 24) * 0.59,
                ),
              ),
              DataColumn(
                label: Container(
                  width: (MediaQuery.of(context).size.width - 4.5 * 24) * 0.24,
                ),
                numeric: false,
              ),
              DataColumn(
                  label: Container(
                    width:
                        (MediaQuery.of(context).size.width - 4.5 * 24) * 0.17,
                  ),
                  numeric: true),
            ],
            rows: records
                .map(
                  (recordUser) => DataRow(
                    cells: [
                      DataCell(
                        Container(
                          alignment: Alignment.centerLeft,
                          width:
                              (MediaQuery.of(context).size.width - 4.5 * 24) *
                                  0.59,
                          height: 48,
                          child: Text(recordUser.name),
                        ),
                        onTap: () =>
                            tappedOnMood(context, recordUser.collectionName),
                      ),
                      DataCell(
                          Container(
                            alignment: Alignment.centerLeft,
                            width:
                                (MediaQuery.of(context).size.width - 4.5 * 24) *
                                    0.24,
                            height: 48,
                            child: Text(recordUser.category == 0
                                ? "I do this"
                                : recordUser.category == 1
                                    ? "I did this"
                                    : recordUser.category == 2
                                        ? "I will do this"
                                        : ""),
                          ),
                          onTap: () =>
                              tappedOnMood(context, recordUser.collectionName)),
                      DataCell(
                        Container(
                            alignment: Alignment.centerRight,
                            width:
                                (MediaQuery.of(context).size.width - 4.5 * 24) *
                                    0.17,
                            height: 48,
                            child: Text(recordUser.rating == 0
                                ? "NaN"
                                : recordUser.rating.toString())),
                        placeholder: recordUser.rating == 0,
                        onTap: () =>
                            tappedOnMood(context, recordUser.collectionName),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    */
  }
}
