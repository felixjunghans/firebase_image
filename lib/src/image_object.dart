import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseImageObject {
  int version;
  final Reference reference;
  String? localPath;
  String remotePath;
  final String bucket;
  final String uri;
  final String originalUri;

  FirebaseImageObject({
    this.version = -1,
    required this.reference,
    this.localPath,
    required this.bucket,
    required this.remotePath,
  })  : uri = '$bucket$remotePath',
        originalUri =
            '$bucket${remotePath.replaceAll('_200x200', '').replaceAll('_800x800', '')}';

  Map<String, dynamic> toMap() {
    return {
      'version': this.version,
      'localPath': this.localPath,
      'bucket': this.bucket,
      'remotePath': this.remotePath,
      'uri': this.uri,
    };
  }

  factory FirebaseImageObject.fromMap(Map<String, dynamic> map,
      [FirebaseApp? firebaseApp]) {
    final String bucket = map['bucket'];
    final String remotePath = map['remotePath'];
    return FirebaseImageObject(
      version: map["version"] ?? -1,
      localPath: map["localPath"],
      reference: _getImageRef(bucket, remotePath, firebaseApp),
      bucket: bucket,
      remotePath: remotePath,
    );
  }

  static Reference _getImageRef(
      String bucket, String remotePath, FirebaseApp? firebaseApp) {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(app: firebaseApp, bucket: bucket);
    return storage.ref().child(remotePath);
  }
}
