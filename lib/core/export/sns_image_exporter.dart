import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures the widget behind [boundaryKey] as PNG, writes to a temp file,
/// and opens the OS share sheet so the user can save it to Photos.
class SnsImageExporter {
  SnsImageExporter._();

  /// Higher pixelRatio = sharper output. For 1080×1920 logical size we
  /// don't need >1.0 since the widget is already laid out at full pixels.
  static const double _pixelRatio = 1.0;

  static Future<File> capturePng({
    required GlobalKey boundaryKey,
    required String filename,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Boundary not found — widget not mounted yet.');
    }
    final ui.Image image = await boundary.toImage(pixelRatio: _pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Failed to encode PNG.');
    }
    final bytes = byteData.buffer.asUint8List();

    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> share({
    required GlobalKey boundaryKey,
    required String filename,
    String? text,
  }) async {
    final file = await capturePng(
      boundaryKey: boundaryKey,
      filename: filename,
    );
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: text,
    );
  }
}
