import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

const int _maxBytes = 5 * 1024 * 1024;

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
  await ref.putData(
    jpegBytes,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  return ref.getDownloadURL();
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
