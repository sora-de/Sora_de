import 'package:flutter_test/flutter_test.dart';
import 'package:sorade/services/storage_probe.dart';

void main() {
  test('minimalProbeJpegBytes is a JPEG file header', () {
    final b = minimalProbeJpegBytes();
    expect(b.length, greaterThan(40));
    expect(b[0], 0xFF);
    expect(b[1], 0xD8);
  });
}
