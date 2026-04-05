import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

const int _maxBytes = 5 * 1024 * 1024;

Future<String> _getDownloadUrlWithRetry(Reference ref) async {
  for (var attempt = 0; attempt < 6; attempt++) {
    try {
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' && attempt < 5) {
        await Future<void>.delayed(Duration(milliseconds: 150 * (attempt + 1)));
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
  final ref = FirebaseStorage.instance.ref('users/$uid/inventory_photos/$itemId.jpg');
  final snapshot = await ref.putData(
    jpegBytes,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  return _getDownloadUrlWithRetry(snapshot.ref);
}

Future<void> deleteInventoryPhotoFile({
  required String uid,
  required String itemId,
}) async {
  try {
    await FirebaseStorage.instance.ref('users/$uid/inventory_photos/$itemId.jpg').delete();
  } catch (_) {}
}

class InventoryPhotoException implements Exception {
  InventoryPhotoException(this.message);
  final String message;
}
