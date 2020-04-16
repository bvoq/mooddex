import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mooddex_client/moodDetail.dart';

import 'guide.dart';
import 'moodHome.dart';
import 'record.dart';

import 'dart:core';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share/share.dart';

Future<Uri> createDynamicLink(Record record) async {
  Uri imageURI = Uri.parse(record.imageURL);

  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://mooddex.page.link',
    link:
        Uri.parse('https://dekeyser.ch/mooddex/moods/' + record.collectionName),
    androidParameters: AndroidParameters(
      packageName: 'ch.dekeyser.mooddexClient',
      minimumVersion: 0,
    ),
    iosParameters: IosParameters(
      bundleId: 'ch.dekeyser.mooddexClient',
      minimumVersion: '1.0.0',
      appStoreId: '962194608', //should be changed later.
    ),
    googleAnalyticsParameters: GoogleAnalyticsParameters(
      campaign: 'example-promo',
      medium: 'social',
      source: 'orkut',
    ),
    itunesConnectAnalyticsParameters: ItunesConnectAnalyticsParameters(
      providerToken: '123456',
      campaignToken: 'example-promo',
    ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: record.name,
      description: record.name +
          " is experienced by " +
          record.added.toString() +
          " user" +
          (record.added > 0 ? "s" : "") +
          "!",
      imageUrl: imageURI,
    ),
  );

  final ShortDynamicLink shortDynamicLink = await parameters.buildShortLink();
  final Uri shortUrl = shortDynamicLink.shortUrl;

  return shortUrl;
}

void shareMood(Record record) async {
  Uri urlToShare = await createDynamicLink(record);
  Share.share(urlToShare.toString());
}

void initDynamicLinks(BuildContext context) async {
  final PendingDynamicLinkData data =
      await FirebaseDynamicLinks.instance.getInitialLink();

  final Uri deepLink = data?.link;
  if (deepLink != null) {
    String fullString = deepLink.toString();
    if (fullString.startsWith("https://dekeyser.ch/mooddex/moods/")) {
      String collectionName =
          fullString.substring("https://dekeyser.ch/mooddex/moods/".length);
      debugPrint("First mood: " + collectionName.toString());
      tappedOnMood(context, collectionName);
    }
  }

  FirebaseDynamicLinks.instance.onLink(
      onSuccess: (PendingDynamicLinkData dynamicLink) async {
    final Uri deepLink = dynamicLink?.link;

    if (deepLink != null) {
      //first extract the record
      String fullString = deepLink.toString();
      debugPrint("full second string: " + fullString);
      if (fullString.startsWith("https://dekeyser.ch/mooddex/moods/")) {
        String collectionName =
            fullString.substring("https://dekeyser.ch/mooddex/moods/".length);
        debugPrint("Second mood: " + collectionName.toString());
        tappedOnMood(context, collectionName);
      }
    }
  }, onError: (OnLinkErrorException e) async {
    print('onLinkError');
    print(e.message);
  });
}
