import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/cache_manager_interface.dart' as ficmi;
import 'package:firebase_image/src/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_storage/firebase_storage.dart';

FirebaseImageCacheManager getFirebaseImageCacheManager(
        CacheRefreshStrategy cacheRefreshStrategy) =>
    FirebaseImageCacheManager(cacheRefreshStrategy);

class FirebaseImageCacheManager implements ficmi.FirebaseImageCacheManager {
  static const String key = 'firebase_image';

  final CacheRefreshStrategy cacheRefreshStrategy = CacheRefreshStrategy.NEVER;

  /// Cache currently not supported on Web
  FirebaseImageCacheManager(CacheRefreshStrategy cacheRefreshStrategy);

  Future<void> open() async {}

  Future<bool> checkDatabaseForEntry(FirebaseImageObject object) async {
    return false;
  }

  Future<FirebaseImageObject?> get(String uri, FirebaseImage image) async {
    return null;
  }

  Reference getImageRef(FirebaseImageObject object, FirebaseApp? firebaseApp) {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(app: firebaseApp, bucket: object.bucket);
    return storage.ref().child(object.remotePath);
  }

  Future<void> checkForUpdate(
      FirebaseImageObject object, FirebaseImage image) async {
    int remoteVersion = (await object.reference.getMetadata())
            .updated
            ?.millisecondsSinceEpoch ??
        -1;
    if (remoteVersion != object.version) {
      // If true, download new image for next load
      await this.upsertRemoteFileToCache(object, image.maxSizeBytes);
    }
  }

  Future<List<FirebaseImageObject>> getAll() async {
    return List.empty();
  }

  Future<int> delete(String uri) async {
    return 0;
  }

  Future<Uint8List?> localFileBytes(FirebaseImageObject? object) async {
    return null;
  }

  Future<Uint8List?> remoteFileBytes(
      FirebaseImageObject object, int maxSizeBytes) {
    return object.reference.getData(maxSizeBytes);
  }

  Future<Uint8List?> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes,
      {FirebaseImageType firebaseImageType =
          FirebaseImageType.original}) async {
    if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
      object.version = (await object.reference.getMetadata())
              .updated
              ?.millisecondsSinceEpoch ??
          0;
    }
    Uint8List? bytes = await remoteFileBytes(object, maxSizeBytes);
    return bytes;
  }

  Future<void> close() async {}

  @override
  Future<FirebaseImageObject> putFile(FirebaseImageObject object, bytes) {
    throw UnimplementedError();
  }
}
