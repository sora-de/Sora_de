import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// On Windows, [Reference.putData] has had SDK bugs; [putFile] is reliable.
Future<TaskSnapshot> putInventoryPhotoBytes(
  Reference ref,
  Uint8List jpegBytes,
  SettableMetadata metadata,
) async {
  if (defaultTargetPlatform == TargetPlatform.windows) {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}sorade_inv_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(jpegBytes, flush: true);
    try {
      return await ref.putFile(file, metadata);
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
  return await ref.putData(jpegBytes, metadata);
}
