import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'package:sorade/services/inventory_photo_storage_rest.dart';
import 'package:sorade/services/inventory_photo_upload_stub.dart'
    if (dart.library.io) 'package:sorade/services/inventory_photo_upload_io.dart';

const int _maxBytes = 5 * 1024 * 1024;

bool get _isWindowsDesktop =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

FirebaseStorage _appStorage() {
  final app = Firebase.app();
  final bucket = app.options.storageBucket;
  if (bucket != null && bucket.isNotEmpty) {
    return FirebaseStorage.instanceFor(app: app, bucket: bucket);
  }
  return FirebaseStorage.instance;
}

bool _isNotYetVisibleStorageError(FirebaseException e) {
  return e.code == 'object-not-found' || e.code == 'not-found';
}

/// After [putFile]/[putData], the object can lag before metadata/URL are readable.
Future<String> _getDownloadUrlWithRetry(Reference ref) async {
  const attempts = 10;
  const baseDelayMs = 100;

  for (var i = 0; i < attempts; i++) {
    try {
      await ref.getMetadata();
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (_isNotYetVisibleStorageError(e) && i < attempts - 1) {
        final ms = (baseDelayMs + i * 55).clamp(100, 1600).toInt();
        await Future<void>.delayed(Duration(milliseconds: ms));
        continue;
      }
      rethrow;
    }
  }
  throw InventoryPhotoException('Could not get image link after upload.');
}

/// Uploads JPEG bytes to `users/{uid}/inventory_photos/{itemId}.jpg`.
Future<String> uploadInventoryPhotoJpeg({
  required String uid,
  required String itemId,
  required Uint8List jpegBytes,
}) async {
  if (jpegBytes.length > _maxBytes) {
    throw InventoryPhotoException('Image must be under 5 MB.');
  }
  // Windows: GCS JSON API rejects Firebase ID tokens; v0 POST 404s on *.firebasestorage.app.
  // Upload bytes with the native plugin, then read metadata + token via Firebase v0 REST GET.
  if (_isWindowsDesktop) {
    final bucket = Firebase.app().options.storageBucket;
    if (bucket == null || bucket.isEmpty) {
      throw InventoryPhotoException('Firebase Storage bucket is not configured.');
    }
    final ref = _appStorage().ref('users/$uid/inventory_photos/$itemId.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final snapshot = await putInventoryPhotoBytes(ref, jpegBytes, metadata);
    try {
      return await resolveInventoryPhotoDownloadUrlFirebaseRest(
        uid: uid,
        itemId: itemId,
        configuredBucket: bucket,
      );
    } on StorageRestException catch (e) {
      try {
        return await _getDownloadUrlWithRetry(snapshot.ref);
      } catch (_) {
        throw InventoryPhotoException(e.message);
      }
    }
  }

  final ref = _appStorage().ref('users/$uid/inventory_photos/$itemId.jpg');
  final metadata = SettableMetadata(contentType: 'image/jpeg');
  final snapshot = await putInventoryPhotoBytes(ref, jpegBytes, metadata);
  return _getDownloadUrlWithRetry(snapshot.ref);
}

Future<void> deleteInventoryPhotoFile({
  required String uid,
  required String itemId,
}) async {
  try {
    await _appStorage().ref('users/$uid/inventory_photos/$itemId.jpg').delete();
  } catch (_) {}
}

class InventoryPhotoException implements Exception {
  InventoryPhotoException(this.message);
  final String message;
}

/// User-facing hint for Storage errors (also used by the debug probe).
String describeFirebaseStorageFailure(FirebaseException e) {
  switch (e.code) {
    case 'object-not-found':
    case 'not-found':
      return 'Storage could not read the file after upload. Confirm Storage is enabled '
          'and storage.rules are deployed (`firebase deploy --only storage`).';
    case 'unauthorized':
    case 'permission-denied':
      return 'Rules or auth blocked access. Deploy storage.rules from this repo '
          '(`firebase deploy --only storage`), ensure you are signed in, and check '
          'Firebase Console → App Check if enforcement is on.';
    case 'canceled':
      return 'The upload was canceled.';
    case 'retry-limit-exceeded':
    case 'deadline-exceeded':
      return 'Network timeout — check your connection and try again.';
    default:
      return 'If this persists, open Account & settings → Test Firebase Storage (debug) '
          'for a full report.';
  }
}
