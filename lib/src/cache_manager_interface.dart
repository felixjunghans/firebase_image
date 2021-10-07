import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Reference getImageRef(FirebaseImageObject object, FirebaseApp? firebaseApp);

  Future<List<FirebaseImageObject>> getAll();

  Future<Uint8List?> localFileBytes(FirebaseImageObject? object);

  Future<Uint8List?> remoteFileBytes(
      FirebaseImageObject object, int maxSizeBytes);

  Future<Uint8List?> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes);

  Future<void> close();
}
