import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import 'globalState.dart';
import 'moodDetail.dart';
import 'record.dart';

class MoodAdd extends StatefulWidget {
  final String query;
  const MoodAdd({Key key, @required this.query}) : super(key: key);
  @override
  State<StatefulWidget> createState() => MoodAddState(this.query);
}

class MoodAddState extends State<MoodAdd> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  TextEditingController _nameController;
  TextEditingController _linkController;
  ImageChooser _imageChooser;
  File _imageFile;
  bool triedSubmittingButFailed = false;
  int searchable = 0;

  MoodAddState(String queryName) {
    _nameController = TextEditingController(text: queryName);
    _linkController = TextEditingController();
    _imageFile = null;
  }

  //Record record;
  //Color color = Color.fromRGBO(0, 0, 255, 0.4);

  String _nameValidator(String value) {
    if (value.length <= 4) {
      return 'Name must be longer than 4 characters';
    }
    return null;
  }

  String _linkValidator(String value) {
    if (value == null || value.length == 0) return null;
    if (Uri.parse(value).isAbsolute) return null;
    return "Not a valid absolute link.";
  }

  void publishWidgetAndUpdateScreen(BuildContext context) {
    if (_imageFile != null) {
      debugPrint('Publishing the mood ' + _nameController.text);

      Record r = Record.fromInitializer(
          name: _nameController.text,
          votes: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          imageFileToBeUploaded: _imageFile,
          searchable: (searchable == 0),
          author: globalState.getUser().uid,
          link: _linkController.text);
      Future<void> success = r.publish();

      success.then((value) {
        if (r.uploaded) {
          globalState.addRating(r, 0, 0).then((vo) {
            //r.loadImageFromFirebase().then((void v) {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MoodDetail(
                        initialRecord: r,
                        deviceHeight: MediaQuery.of(context).size.height)));
          });
        } else {}
      });
      //add zero ratings
    } else {
      // just ignore the request, no image selected yet..
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Previous tt: ' + triedSubmittingButFailed.toString());

    _imageChooser = ImageChooser(
      errorColor: triedSubmittingButFailed ? Colors.red : Colors.black,
      onImageSelect: (File returnedImageFile) {
        _imageFile = returnedImageFile;
      },
    );

    return Scaffold(
      body: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            CupertinoNavigationBar(
              middle: Text("Add mood"),
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  child: Icon(
                    CupertinoIcons.back,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
            ),

            Padding(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                child: TextFormField(
                  autocorrect: false,
                  decoration: InputDecoration(
                      labelText: 'Mood name*', hintText: 'Mood name'),
                  controller: _nameController,
                  obscureText: false,
                  maxLength: 45,
                  validator: _nameValidator,
                )),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                child: TextFormField(
                  autocorrect: false,
                  decoration: InputDecoration(
                      labelText: 'Link (optional)', hintText: 'https://...'),
                  controller: _linkController,
                  obscureText: false,
                  maxLength: 200,
                  validator: _linkValidator,
                )),
            _imageChooser,
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Privacy:'),
            ),
            CupertinoSlidingSegmentedControl(
                groupValue: searchable,
                children: const <int, Widget>{
                  0: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      child: Text("Publicly searchable")),
                  1: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      child: Text("Privately shareable")),
                },
                onValueChanged: (i) {
                  setState(() {
                    searchable = i;
                  });
                }),
            Spacer(flex: 5),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: new Text("Add mood"),
              onPressed: () async {
                if (_loginFormKey.currentState.validate()) {
                  publishWidgetAndUpdateScreen(context);
                }
                triedSubmittingButFailed = true;
                setState(() => {});
              },
            ),
            Spacer(flex: 1),
//            Text('Similarly named moods'),
          ],
        ),
      ),
    );
  }
}

typedef ImageCallback = void Function(File imageFile);

class ImageChooser extends StatefulWidget {
  ImageChooser({Key key, this.onImageSelect, this.errorColor})
      : super(key: key);

  final ImageCallback onImageSelect;
  final Color errorColor;

  //ImageChooserState imageChooserState;
  @override
  ImageChooserState createState() => ImageChooserState();
}

class ImageChooserState extends State<ImageChooser> {
  File _imageFile;
  dynamic _pickImageError;
  bool isVideo = false;
  //VideoPlayerController _controller;
  String _retrieveDataError;

  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();

  File getImageFile() {
    return _imageFile; //returns null if not yet chosen!
  }

  void _onImageButtonPressed(ImageSource source, {BuildContext context}) async {
    double maxWidth = 1366; // null
    double maxHeight = 480;
    int quality = 80; //null;

    try {
      _imageFile = await ImagePicker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: quality);
      widget.onImageSelect(_imageFile);
      setState(() {});
    } catch (e) {
      _pickImageError = e;
    }
  }

  @override
  void dispose() {
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    super.dispose();
  }

  Widget _previewImage(BuildContext context) {
    final Text retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_imageFile != null) {
      return ConstrainedBox(
          constraints: new BoxConstraints(
            minHeight: 0,
            minWidth: 0,
            maxHeight: 235,
            maxWidth: MediaQuery.of(context).size.width,
          ),
          child: Image.file(_imageFile, fit: BoxFit.cover));
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      );
    } else {
      return Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
        style: TextStyle(color: widget.errorColor),
      );
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await ImagePicker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      if (response.type == RetrieveType.image) {
        isVideo = false;
        setState(() {
          _imageFile = response.file;
        });
      }
    } else {
      _retrieveDataError = response.exception.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.add_a_photo, color: Colors.grey),
          onPressed: () {
            isVideo = false;
            _onImageButtonPressed(ImageSource.gallery, context: context);
          },
        ),
        Platform.isAndroid
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Text(
                        'You have not yet picked an image.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: widget.errorColor),
                      );
                    case ConnectionState.done:
                      return _previewImage(context);
                    default:
                      if (snapshot.hasError) {
                        return Text(
                          'Pick image error: ${snapshot.error}}',
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return Text(
                          'You have not yet picked an image.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: widget.errorColor),
                        );
                      }
                  }
                },
              )
            : _previewImage(context)
      ],
    );
    /*
    Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Platform.isAndroid
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Text(
                        'You have not yet picked an image.',
                        textAlign: TextAlign.center,
                      );
                    case ConnectionState.done:
                      return _previewImage();
                    default:
                      if (snapshot.hasError) {
                        return Text(
                          'Pick image/video error: ${snapshot.error}}',
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return const Text(
                          'You have not yet picked an image.',
                          textAlign: TextAlign.center,
                        );
                      }
                  }
                },
              )
            : _previewImage(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              isVideo = false;
              _onImageButtonPressed(ImageSource.gallery, context: context);
            },
            heroTag: 'image0',
            tooltip: 'Pick Image from gallery',
            child: const Icon(Icons.photo_library),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.camera, context: context);
              },
              heroTag: 'image1',
              tooltip: 'Take a Photo',
              child: const Icon(Icons.camera_alt),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                isVideo = true;
                _onImageButtonPressed(ImageSource.gallery);
              },
              heroTag: 'video0',
              tooltip: 'Pick Video from gallery',
              child: const Icon(Icons.video_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                isVideo = true;
                _onImageButtonPressed(ImageSource.camera);
              },
              heroTag: 'video1',
              tooltip: 'Take a Video',
              child: const Icon(Icons.videocam),
            ),
          ),
        ],
      ),
    );
    */
  }

  Text _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }
}

typedef void OnPickImageCallback(
    double maxWidth, double maxHeight, int quality);
