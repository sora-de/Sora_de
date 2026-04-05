import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sorade/services/inventory_photo_storage.dart';
import 'package:uuid/uuid.dart';

/// Tiny valid JPEG (1×1) for Storage diagnostics — same rules path as inventory photos.
Uint8List minimalProbeJpegBytes() {
  return Uint8List.fromList(_minimalJpegBytes);
}

/// Standard minimal JPEG (1×1 pixel), ~160 bytes.
const List<int> _minimalJpegBytes = <int>[
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48,
  0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08,
  0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
  0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20,
  0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27,
  0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
  0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xFF, 0xDA, 0x00, 0x08,
  0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x6A, 0xFF, 0xD9,
];

/// Outcome of [runFirebaseStorageProbe].
class StorageProbeResult {
  StorageProbeResult._({
    required this.ok,
    this.downloadUrl,
    this.detail,
    this.bucket,
  });

  factory StorageProbeResult.success(String url, String bucket) {
    return StorageProbeResult._(ok: true, downloadUrl: url, bucket: bucket);
  }

  factory StorageProbeResult.failure(String detail, {String? bucket}) {
    return StorageProbeResult._(ok: false, detail: detail, bucket: bucket);
  }

  final bool ok;
  final String? downloadUrl;
  final String? detail;
  final String? bucket;

  String get summary {
    final b = bucket != null ? 'Bucket: $bucket\n\n' : '';
    if (ok) {
      return '${b}Upload + download URL succeeded.\n\n$downloadUrl';
    }
    return '$b$detail';
  }
}

/// Runs the same upload path as inventory photos (then deletes the probe file).
///
/// Requires a signed-in user. Use from debug UI to see the real Firebase error.
Future<StorageProbeResult> runFirebaseStorageProbe() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return StorageProbeResult.failure('Not signed in. Sign in first.');
  }

  final app = Firebase.app();
  final bucket = app.options.storageBucket;

  final uid = user.uid;
  final id = 'probe_${const Uuid().v4()}';

  try {
    final url = await uploadInventoryPhotoJpeg(
      uid: uid,
      itemId: id,
      jpegBytes: minimalProbeJpegBytes(),
    );
    await deleteInventoryPhotoFile(uid: uid, itemId: id);
    return StorageProbeResult.success(url, bucket ?? '(default)');
  } on InventoryPhotoException catch (e) {
    return StorageProbeResult.failure(
      'InventoryPhotoException: ${e.message}',
      bucket: bucket,
    );
  } on FirebaseException catch (e) {
    return StorageProbeResult.failure(
      'Firebase [${e.code}] ${e.message ?? ""}\n'
      '${describeFirebaseStorageFailure(e)}',
      bucket: bucket,
    );
  } catch (e, st) {
    return StorageProbeResult.failure(
      '$e\n\n$st',
      bucket: bucket,
    );
  }
}
