import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

html.VideoElement? _video;
html.CanvasElement? _canvas;

Future<void> initCamera() async {}

Widget buildCameraView() {
  _video = html.VideoElement()
    ..autoplay = true
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover';

  _canvas = html.CanvasElement(width: 640, height: 480);

  html.window.navigator.mediaDevices
      ?.getUserMedia({'video': true, 'audio': false}).then((stream) {
    _video!.srcObject = stream;
  });

  ui.platformViewRegistry.registerViewFactory(
    'camera-view',
    (int viewId) => _video!,
  );

  return const HtmlElementView(viewType: 'camera-view');
}

Future<String?> capturarFrame(dynamic a, dynamic b) async {
  if (_video == null || _canvas == null) return null;
  final ctx = _canvas!.context2D;
  ctx.drawImageScaled(_video!, 0, 0, 640, 480);
  final dataUrl = _canvas!.toDataUrl('image/jpeg', 0.8);
  return dataUrl.split(',')[1];
}