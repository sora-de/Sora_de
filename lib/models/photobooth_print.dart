import 'package:flutter/foundation.dart';

@immutable
class PhotoboothPrint {
  const PhotoboothPrint({
    required this.id,
    required this.boothId,
    required this.source,
    required this.mode,
    required this.sheets,
    required this.timestamp,
  });

  final String id; // clientEventId
  final String boothId;
  final String source; // guest, reprint
  final String mode; // Photo Strip, Polaroid, GIF
  final int sheets;
  final DateTime timestamp;
}
