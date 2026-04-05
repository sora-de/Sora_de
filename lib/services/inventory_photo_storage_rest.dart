import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Thrown when Firebase Storage REST metadata calls fail.
class StorageRestException implements Exception {
  StorageRestException(this.message);
  final String message;

  @override
  String toString() => message;
}

String _objectPath(String uid, String itemId) =>
    'users/$uid/inventory_photos/$itemId.jpg';

String? _extractDownloadToken(Map<String, dynamic> json) {
  final top = json['downloadTokens'];
  if (top is String && top.trim().isNotEmpty) {
    return top.split(',').first.trim();
  }
  final meta = json['metadata'];
  if (meta is Map<String, dynamic>) {
    final t = meta['firebaseStorageDownloadTokens'];
    if (t is String && t.trim().isNotEmpty) {
      return t.split(',').first.trim();
    }
  }
  return null;
}

/// Same physical bucket may be reachable under more than one id in REST URLs.
List<String> _bucketCandidates(String configuredBucket, String projectId) {
  final out = <String>{configuredBucket.trim()};
  if (configuredBucket.endsWith('.firebasestorage.app') && projectId.isNotEmpty) {
    out.add('$projectId.appspot.com');
  }
  if (configuredBucket.endsWith('.appspot.com') && projectId.isNotEmpty) {
    out.add('$projectId.firebasestorage.app');
  }
  return out.toList();
}

/// After a **native** [putFile]/[putData] upload, read object metadata via Firebase v0
/// REST (accepts the Firebase ID token). Avoids [Reference.getDownloadURL] on Windows
/// where the Storage plugin’s channel is unreliable.
///
/// Does **not** use `storage.googleapis.com` JSON upload — that API expects OAuth, not
/// a Firebase ID token.
Future<String> resolveInventoryPhotoDownloadUrlFirebaseRest({
  required String uid,
  required String itemId,
  required String configuredBucket,
  http.Client? client,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StorageRestException('Not signed in.');
  }
  final idToken = await user.getIdToken();
  if (idToken == null || idToken.isEmpty) {
    throw StorageRestException('Could not get ID token for Storage.');
  }

  final projectId = Firebase.app().options.projectId;
  final buckets = _bucketCandidates(configuredBucket, projectId);
  final objectPath = _objectPath(uid, itemId);
  final pathSeg = Uri.encodeComponent(objectPath);

  final c = client ?? http.Client();
  try {
    for (final tryBucket in buckets) {
      final base =
          'https://firebasestorage.googleapis.com/v0/b/$tryBucket/o/$pathSeg';

      for (var attempt = 0; attempt < 36; attempt++) {
        final resp = await c.get(
          Uri.parse(base),
          headers: {'Authorization': 'Bearer $idToken'},
        );

        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is! Map<String, dynamic>) {
            throw StorageRestException('Invalid metadata JSON from Storage.');
          }
          final token = _extractDownloadToken(decoded);
          if (token == null || token.isEmpty) {
            throw StorageRestException(
              'Storage returned metadata but no download token for bucket $tryBucket.',
            );
          }
          return '$base?alt=media&token=$token';
        }

        if (resp.statusCode == 404) {
          if (attempt < 35) {
            final ms = (180 + attempt * 50).clamp(100, 2000).toInt();
            await Future<void>.delayed(Duration(milliseconds: ms));
            continue;
          }
          break;
        }

        if (resp.statusCode == 401 || resp.statusCode == 403) {
          throw StorageRestException(
            'Storage rules or auth blocked metadata read (${resp.statusCode}): '
            '${resp.body}',
          );
        }

        throw StorageRestException(
          'Storage metadata GET failed (${resp.statusCode}): ${resp.body}',
        );
      }
    }

    throw StorageRestException(
      'Could not read upload metadata after trying buckets: ${buckets.join(", ")}. '
      'Confirm Firebase Storage is enabled and storage.rules are deployed.',
    );
  } finally {
    if (client == null) {
      c.close();
    }
  }
}
