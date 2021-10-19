import 'dart:typed_data';

import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';

FirebaseImageCacheManager getFirebaseImageCacheManager(
        CacheRefreshStrategy cacheRefreshStrategy) =>
    throw UnimplementedError('getFirebaseImageCacheManager');

abstract class FirebaseImageCacheManager {
  factory FirebaseImageCacheManager(
          CacheRefreshStrategy cacheRefreshStrategy) =>
      getFirebaseImageCacheManager(cacheRefreshStrategy);

  Future<void> open();

  Future<bool> checkDatabaseForEntry(FirebaseImageObject object);

  Future<FirebaseImageObject?> get(String uri, FirebaseImage image);

  Future<List<FirebaseImageObject>> getAll();

  Future<Uint8List?> localFileBytes(FirebaseImageObject? object);

  Future<Uint8List?> remoteFileBytes(
      FirebaseImageObject object, int maxSizeBytes);

  Future<Uint8List?> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes);

  Future<void> close();
}
