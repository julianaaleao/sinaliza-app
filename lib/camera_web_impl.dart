import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:async';

html.VideoElement? _video;
html.CanvasElement? _canvas;
bool _cameraReady = false;

Future<void> initCamera() async {
  _video = html.VideoElement()
    ..autoplay = true
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover';

  // 320x240 basta para o MediaPipe e deixa cada envio de ~1,5s leve
  _canvas = html.CanvasElement(width: 320, height: 240);

  final completer = Completer<void>();

  html.window.navigator.mediaDevices
      ?.getUserMedia({
        'video': true,
        'audio': false
      }).then((stream) {
    _video!.srcObject = stream;
    _video!.onLoadedMetadata.listen((_) {
      _cameraReady = true;
      if (!completer.isCompleted) completer.complete();
    });
  }).catchError((e) {
    if (!completer.isCompleted) completer.complete();
  });

  ui.platformViewRegistry.registerViewFactory(
    'camera-view',
    (int viewId) => _video!,
  );

  return completer.future;
}

Widget buildCameraView() {
  return const HtmlElementView(viewType: 'camera-view');
}

Future<String?> capturarFrame(dynamic a, dynamic b) async {
  if (_video == null || _canvas == null || !_cameraReady) return null;
  final ctx = _canvas!.context2D;
  ctx.drawImageScaled(_video!, 0, 0, 320, 240);
  final dataUrl = _canvas!.toDataUrl('image/jpeg', 0.7);
  return dataUrl.split(',')[1];
}