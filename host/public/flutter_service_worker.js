'use strict';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "index.html": "161ecaed79103cd262f7c9b90a41fb7c",
"/": "161ecaed79103cd262f7c9b90a41fb7c",
"main.dart.js": "580bf75f66306f65fc40bd7df1872dc1",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "5e50f77ac0f998f773e677c6f7645b52",
"assets/LICENSE": "44ac7d86e096cb27377f40d17e876fcc",
"assets/images/gondolaupside.png": "72dec79d1540d36b6fd615521d68818d",
"assets/images/gondola.png": "b646641f0e7ef52e201ccc7e4ca5b334",
"assets/images/philosopher.png": "284cad02b0bb8b407720fee454b76232",
"assets/AssetManifest.json": "a16fbdfa62553511d600a130d3b2a21a",
"assets/FontManifest.json": "01700ba55b08a6141f33e168c4a6c22f",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "115e937bb829a890521f72d2e664b632",
"assets/fonts/MaterialIcons-Regular.ttf": "56d3ffdef7a25659eab6a68a3fbfaf16"
};

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (cacheName) {
      return caches.delete(cacheName);
    }).then(function (_) {
      return caches.open(CACHE_NAME);
    }).then(function (cache) {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

self.addEventListener('fetch', function (event) {
  event.respondWith(
    caches.match(event.request)
      .then(function (response) {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});
