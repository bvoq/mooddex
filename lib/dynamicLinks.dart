import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mooddex_client/moodDetail.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share_plus/share_plus.dart';
import "package:universal_html/html.dart" as html;
//import 'package:universal_html/prefer_universal/html.dart' as html;

import 'record.dart';
import 'dart:io' show Platform;

Future<Uri> createDynamicLink(Record record) async {
  Uri imageURI = Uri.parse(record.imageURL);

  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://mood-dex.com/dy',
    link: Uri.parse('https://mood-dex.com/?' + record.collectionName),
    androidParameters: AndroidParameters(
      packageName: 'ch.dekeyser.mooddex_client',
      minimumVersion: 0,
    ),
    iosParameters: IOSParameters(
      bundleId: 'ch.dekeyser.mooddexClient',
      minimumVersion: '1.0.0',
      appStoreId: '1508217727', //should be changed later.
    ),
    /*
    googleAnalyticsParameters: GoogleAnalyticsParameters(
      campaign: 'example-promo',
      medium: 'social',
      source: 'orkut',
    ),
    itunesConnectAnalyticsParameters: ItunesConnectAnalyticsParameters(
      providerToken: '123456',
      campaignToken: 'example-promo',
    ),*/
    socialMetaTagParameters: SocialMetaTagParameters(
      title: record.name,
      description: record.name +
          " is experienced by " +
          record.added.toString() +
          " user" +
          (record.added != 1 ? "s" : "") +
          "!\n" +
          record.link +
          "\n",
      //globalState.topGuideComment,
      imageUrl: imageURI,
    ),
  );

  final ShortDynamicLink shortDynamicLink =
      await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  final Uri longUrl = await FirebaseDynamicLinks.instance.buildLink(parameters);
  ;

  final Uri shortUrl = shortDynamicLink.shortUrl;
  debugPrint("shortUrl: " + shortUrl.toString());
  debugPrint("longUrl: " + longUrl.toString());

  return shortUrl;
}

Future<void> shareMood(Record record) async {
  Uri urlToShare = await createDynamicLink(record);
  Share.share(urlToShare.toString());
  return;
}

void initDynamicLinks(BuildContext context) async {
  debugPrint("hello dynamic link");
  if (kIsWeb) {
    debugPrint("dynamic link in web");
    //debugPrint("First web mood: " + html.window.location.href);
    //CHANGE WEB
    String fullString = html.window.location.href;
    String collectionNameWithHashtag = "";
    int locationOfQuestionMark = fullString.indexOf("?");
    if (locationOfQuestionMark > 0) {
      collectionNameWithHashtag =
          fullString.substring(locationOfQuestionMark + 1);

      debugPrint("collectionNameWithHashtag: " + collectionNameWithHashtag);
      while (collectionNameWithHashtag.endsWith("/"))
        collectionNameWithHashtag = collectionNameWithHashtag.substring(
            0, collectionNameWithHashtag.length - 1);
      while (collectionNameWithHashtag.endsWith("#"))
        collectionNameWithHashtag = collectionNameWithHashtag.substring(
            0, collectionNameWithHashtag.length - 1);

      String collectionName = collectionNameWithHashtag;
      tappedOnMood(context, collectionName);
    }
  } else if (Platform.isAndroid || Platform.isIOS) {
    debugPrint("dynamic link android and ios mood");
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();

    if (data != null) {
      //final PendingDynamicLinkData data = null;
      final Uri deepLink = data.link;
      debugPrint("dynamic link after deeplink");
      String fullString = deepLink.toString();
      if (fullString.startsWith("https://mood-dex.com/?")) {
        String collectionName =
            fullString.substring("https://mood-dex.com/?".length);
        tappedOnMood(context, collectionName);
      } else if (fullString.startsWith("https://mood-dex.com/?")) {
        String collectionName =
            fullString.substring("https://mood-dex.com/?".length);
        tappedOnMood(context, collectionName);
      } else if (fullString.startsWith("https://dekeyser.ch/mooddex/moods/")) {
        //pre version
        String collectionName =
            fullString.substring("https://dekeyser.ch/mooddex/moods/".length);
        tappedOnMood(context, collectionName);
      }
    }

    FirebaseDynamicLinks.instance.onLink.listen(
        (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink.link;

      if (deepLink != null) {
        //first extract the record
        String fullString = deepLink.toString();
        debugPrint("dynamic link input string: " + fullString);
        if (fullString.startsWith("https://mood-dex.com/moods?")) {
          String collectionName =
              fullString.substring("https://mood-dex.com/moods?".length);
          tappedOnMood(context, collectionName);
        } else if (fullString.startsWith("https://mood-dex.com/?")) {
          String collectionName =
              fullString.substring("https://mood-dex.com/?".length);
          tappedOnMood(context, collectionName);
        } else if (fullString
            .startsWith("https://dekeyser.ch/mooddex/moods/")) {
          //pre version
          String collectionName =
              fullString.substring("https://dekeyser.ch/mooddex/moods/".length);
          tappedOnMood(context, collectionName);
        }
      }
    }, onError: (Object o, StackTrace st) async {
      print('dynamic link onLinkError ' + o.toString());
    });
  }
}
