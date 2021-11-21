import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/cache_manager_interface.dart' as ficmi;
import 'package:firebase_image/src/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

FirebaseImageCacheManager getFirebaseImageCacheManager(
        CacheRefreshStrategy cacheRefreshStrategy) =>
    FirebaseImageCacheManager(cacheRefreshStrategy);

class FirebaseImageCacheManager implements ficmi.FirebaseImageCacheManager {
  static const String key = 'firebase_image';

  late Database db;
  static const String dbName = '$key.db';
  static const String table = 'images';
  late String basePath;

  final CacheRefreshStrategy cacheRefreshStrategy;

  FirebaseImageCacheManager(
    this.cacheRefreshStrategy,
  );

  Future<void> open() async {
    db = await openDatabase(
      join((await getDatabasesPath()), dbName),
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $table (
            uri TEXT PRIMARY KEY,
            remotePath TEXT, 
            localPath TEXT, 
            bucket TEXT, 
            version INTEGER
          )
        ''');
      },
      version: 1,
    );
    basePath = await _createFilePath();
  }

  Future<FirebaseImageObject> insert(FirebaseImageObject model) async {
    await db.insert(table, model.toMap());
    return model;
  }

  Future<FirebaseImageObject> update(FirebaseImageObject model) async {
    await db.update(
      table,
      model.toMap(),
      where: 'uri = ?',
      whereArgs: [model.uri],
    );
    return model;
  }

  Future<FirebaseImageObject> upsert(FirebaseImageObject object) async {
    if (await checkDatabaseForEntry(object)) {
      return await update(object);
    } else {
      return await insert(object);
    }
  }

  Future<bool> checkDatabaseForEntry(FirebaseImageObject object) async {
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      columns: const ['uri'],
      where: 'uri = ?',
      whereArgs: [object.uri],
    );
    return maps.length > 0;
  }

  Future<FirebaseImageObject?> get(String uri, FirebaseImage image) async {
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      columns: const [
        'remotePath',
        'localPath',
        'bucket',
        'version',
      ],
      where: 'uri = ?',
      whereArgs: [uri],
    );
    if (maps.length > 0) {
      final FirebaseImageObject returnObject =
          FirebaseImageObject.fromMap(maps.first, image.firebaseApp);
      if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
        checkForUpdate(returnObject, image); // Check for update in background
      }
      return returnObject;
    }
    return null;
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
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return FirebaseImageObject.fromMap(maps[i]);
    });
  }

  Future<int> delete(String uri) async {
    return await db.delete(
      table,
      where: 'uri = ?',
      whereArgs: [uri],
    );
  }

  Future<Uint8List?> localFileBytes(FirebaseImageObject? object) async {
    if (await _fileExists(object)) {
      return File(object!.localPath!).readAsBytes();
    }
    return null;
  }

  Future<Uint8List?> remoteFileBytes(
      FirebaseImageObject object, int maxSizeBytes,
      {FirebaseImageType firebaseImageType = FirebaseImageType.original}) {
    var reference;

    switch (firebaseImageType) {
      case FirebaseImageType.thumb:
        final path = object.remotePath
            .replaceAll('.jpg', '_200x200.jpg')
            .replaceAll('.png', '_200x200.jpg');
        reference = FirebaseStorage.instance.ref(path);
        break;
      case FirebaseImageType.highRes:
        final path = object.remotePath
            .replaceAll('.jpg', '_800x800.jpg')
            .replaceAll('.png', '_800x800.jpg');
        reference = FirebaseStorage.instance.ref(path);
        break;
      case FirebaseImageType.original:
        reference = object.reference;
        break;
    }

    return reference.getData(maxSizeBytes);
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
    Uint8List? bytes = await remoteFileBytes(object, maxSizeBytes,
        firebaseImageType: firebaseImageType);
    await putFile(object, bytes, firebaseImageType: firebaseImageType);
    return bytes;
  }

  Future<FirebaseImageObject> putFile(FirebaseImageObject object, final bytes,
      {FirebaseImageType firebaseImageType =
          FirebaseImageType.original}) async {
    String path = basePath + "/" + object.remotePath;
    path = path.replaceAll("//", "/");
    //print(join(basePath, object.remotePath)); Join isn't working?
    final localFile = await File(path).create(recursive: true);
    await localFile.writeAsBytes(bytes);
    object.localPath = localFile.path;
    switch (firebaseImageType) {
      case FirebaseImageType.thumb:
        object.remotePath = object.remotePath
            .replaceAll('.jpg', '_200x200.jpg')
            .replaceAll('.png', '_200x200.jpg');
        break;
      case FirebaseImageType.highRes:
        object.remotePath = object.remotePath
            .replaceAll('.jpg', '_800x800.jpg')
            .replaceAll('.png', '_800x800.jpg');
        break;
      case FirebaseImageType.original:
        break;
    }
    return await upsert(object);
  }

  Future<bool> _fileExists(FirebaseImageObject? object) async {
    if (object?.localPath == null) {
      return false;
    }
    return File(object!.localPath!).exists();
  }

  Future<String> _createFilePath() async {
    final directory = await getTemporaryDirectory();
    return join(directory.path, key);
  }

  Future<void> close() => db.close();
}
