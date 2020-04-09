import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

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
  ImageChooser _imageChooser;
  File _imageFile;
  bool triedSubmittingButFailed = false;

  MoodAddState(String queryName) {
    _nameController = TextEditingController(text: queryName);
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

  void publishWidgetAndUpdateScreen(BuildContext context) {
    if (_imageFile != null) {
      debugPrint('Publishing the mood ' + _nameController.text);
      Record r = Record.fromInitializer(
          _nameController.text, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], _imageFile);
      Future<void> success = r.publish();

      success.then((value) {
        if (r.uploaded) {
          //r.loadImageFromFirebase().then((void v) {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MoodDetail(initialRecord: r),
              ));
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
      appBar: AppBar(
        title: Text('Add Mood'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.queue),
              onPressed: () {
                if (_loginFormKey.currentState.validate()) {
                  publishWidgetAndUpdateScreen(context);
                }
                triedSubmittingButFailed = true;
                setState(() => {});
              }),
        ],
      ),
      body: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            _imageChooser,
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            ),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            ),
            Text('Similarly named moods'),
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

  Widget _previewImage() {
    final Text retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_imageFile != null) {
      return Image.file(_imageFile);
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
                      return _previewImage();
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
            : _previewImage()
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

  Future<void> _displayPickImageDialog(
      BuildContext context, OnPickImageCallback onPick) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add optional parameters'),
            content: Column(
              children: <Widget>[
                TextField(
                  controller: maxWidthController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(hintText: "Enter maxWidth if desired"),
                ),
                TextField(
                  controller: maxHeightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(hintText: "Enter maxHeight if desired"),
                ),
                TextField(
                  controller: qualityController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(hintText: "Enter quality if desired"),
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                  child: const Text('PICK'),
                  onPressed: () {
                    double width = maxWidthController.text.isNotEmpty
                        ? double.parse(maxWidthController.text)
                        : null;
                    double height = maxHeightController.text.isNotEmpty
                        ? double.parse(maxHeightController.text)
                        : null;
                    int quality = qualityController.text.isNotEmpty
                        ? int.parse(qualityController.text)
                        : null;
                    onPick(width, height, quality);
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }
}

typedef void OnPickImageCallback(
    double maxWidth, double maxHeight, int quality);
