import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfSaveResult {
  const PdfSaveResult({required this.path, required this.shared});

  final String path;
  final bool shared;
}

/// Saves PDF and opens the system share sheet (open with PDF viewer / save).
Future<PdfSaveResult> saveAndOpenPdf({
  required Uint8List bytes,
  required String baseName,
}) async {
  if (bytes.isEmpty) {
    throw Exception('PDF file is empty');
  }

  final safe = baseName.replaceAll(RegExp(r'[^\w.-]+'), '_');
  final fileName = safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';

  if (kIsWeb) {
    throw UnsupportedError('PDF share is not supported on web yet');
  }

  Directory dir;
  if (Platform.isAndroid) {
    final downloads = Directory('/storage/emulated/0/Download');
    if (await downloads.exists()) {
      dir = downloads;
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  final result = await Share.shareXFiles(
    [
      XFile(
        file.path,
        mimeType: 'application/pdf',
        name: fileName,
      ),
    ],
    subject: 'Your Dream Cars — delivery note',
    text: 'Vehicle delivery note PDF',
  );

  final shared = result.status != ShareResultStatus.dismissed;
  return PdfSaveResult(path: file.path, shared: shared);
}
