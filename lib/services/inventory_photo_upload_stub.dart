import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

Future<TaskSnapshot> putInventoryPhotoBytes(
  Reference ref,
  Uint8List jpegBytes,
  SettableMetadata metadata,
) async {
  return ref.putData(jpegBytes, metadata);
}
