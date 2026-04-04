import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sorade/l10n/app_localizations.dart';

Future<void> shareMonthlyCsv(
  BuildContext context,
  String csv,
  DateTime month,
) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final dir = await getTemporaryDirectory();
    final name =
        'sorade_${month.year}_${month.month.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(csv, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: name)],
      subject: l10n.reportsShareCsvSubject,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareCsvError)),
      );
    }
  }
}
