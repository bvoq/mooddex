import 'dart:core';

import 'package:flutter/material.dart';
import 'package:mooddex_client/moodDetail.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share/share.dart';

import 'globalState.dart';
import 'record.dart';

Future<Uri> createDynamicLink(Record record) async {
  Uri imageURI = Uri.parse(record.imageURL);

  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://mooddex.page.link',
    link:
        Uri.parse('https://dekeyser.ch/mooddex/moods/' + record.collectionName),
    androidParameters: AndroidParameters(
      packageName: 'ch.dekeyser.mooddex_client',
      minimumVersion: 0,
    ),
    iosParameters: IosParameters(
      bundleId: 'ch.dekeyser.mooddexClient',
      minimumVersion: '1.0.0',
      appStoreId: '1508217727', //should be changed later.
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
          "!\n" +
          record.link +
          "\n" +
          globalState.topGuideComment,
      imageUrl: imageURI,
    ),
  );

  final ShortDynamicLink shortDynamicLink = await parameters.buildShortLink();
  final Uri shortUrl = shortDynamicLink.shortUrl;

  // String guideLink;

  return shortUrl;
}

Future<void> shareMood(Record record) async {
  Uri urlToShare = await createDynamicLink(record);
  Share.share(urlToShare.toString());
  return;
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
