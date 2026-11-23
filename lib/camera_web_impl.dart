// Câmera no navegador (getUserMedia + canvas para capturar quadros)
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

enum PermissaoCamera { concedida, negada, naoPerguntada }

html.VideoElement? _video;
// 320x240 basta para o MediaPipe e deixa cada envio leve
final _canvas = html.CanvasElement(width: 320, height: 240);
html.MediaStream? _stream;
bool _pronta = false;
bool _registrada = false;

Future<PermissaoCamera> permissaoCamera() async {
  try {
    final s = await html.window.navigator.permissions
        ?.query({'name': 'camera'});
    switch (s?.state) {
      case 'granted':
        return PermissaoCamera.concedida;
      case 'denied':
        return PermissaoCamera.negada;
    }
  } catch (_) {
    // Navegador sem suporte à consulta (ex.: Firefox): pergunta ao abrir
  }
  return PermissaoCamera.naoPerguntada;
}

Future<bool> pedirPermissaoCamera() async {
  try {
    final s = await html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': false});
    s?.getTracks().forEach((t) => t.stop());
    return s != null;
  } catch (_) {
    return false;
  }
}

// No navegador não dá para abrir os ajustes; tenta pedir de novo
Future<bool> abrirAjustesAparelho() => pedirPermissaoCamera();

Future<void> initCamera({bool frontal = true}) async {
  _video ??= html.VideoElement()
    ..autoplay = true
    ..muted = true
    ..setAttribute('playsinline', 'true')
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover';

  if (!_registrada) {
    // O mesmo <video> é reaproveitado sempre que a câmera muda de lugar
    // na tela (ex.: tela de Conversa). Ao ser movido, o navegador pausa o
    // vídeo e as capturas ficariam congeladas, então ele volta a tocar.
    _video!.onPause.listen((_) => _retomarDepois());
    ui.platformViewRegistry.registerViewFactory('camera-view', (int viewId) {
      _retomarDepois();
      return _video!;
    });
    _registrada = true;
  }

  await pararCamera();
  final completer = Completer<void>();
  try {
    _stream = await html.window.navigator.mediaDevices?.getUserMedia({
      'video': {'facingMode': frontal ? 'user' : 'environment'},
      'audio': false,
    });
    _video!.srcObject = _stream;
    // Espelha a câmera frontal, como um espelho
    _video!.style.transform = frontal ? 'scaleX(-1)' : 'none';
    _video!.onLoadedMetadata.first.then((_) {
      _pronta = true;
      if (!completer.isCompleted) completer.complete();
    });
  } catch (e) {
    debugPrint('Erro ao abrir a câmera: $e');
    if (!completer.isCompleted) completer.complete();
  }
  return completer.future.timeout(const Duration(seconds: 10),
      onTimeout: () {});
}

// Volta a tocar se o vídeo parou com a câmera ainda ligada. Espera um
// pouco porque o elemento pode estar fora da página no meio da troca.
void _retomarDepois() {
  Timer(const Duration(milliseconds: 60), _retomar);
}

Future<void> _retomar() async {
  final v = _video;
  if (v == null || _stream == null || !v.paused) return;
  try {
    await v.play();
  } catch (_) {
    // Ainda fora da página: tenta de novo na próxima captura
  }
}

Future<void> pararCamera() async {
  _pronta = false;
  _stream?.getTracks().forEach((t) => t.stop());
  _stream = null;
}

Widget buildCameraView() {
  if (_video == null) return const SizedBox.expand();
  return const HtmlElementView(viewType: 'camera-view');
}

Future<String?> capturarFrame() async {
  if (_video == null || !_pronta) return null;
  // Garantia extra: nunca capturar de um vídeo parado (quadro congelado)
  if (_video!.paused) await _retomar();
  _canvas.context2D.drawImageScaled(_video!, 0, 0, 320, 240);
  final dataUrl = _canvas.toDataUrl('image/jpeg', 0.7);
  return dataUrl.split(',')[1];
}
