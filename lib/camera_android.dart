// Câmera no Android/iOS (pacote camera + permission_handler)
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissaoCamera { concedida, negada, naoPerguntada }

final _controle = ValueNotifier<CameraController?>(null);
bool _inicializando = false;

Future<PermissaoCamera> permissaoCamera() async {
  final s = await Permission.camera.status;
  if (s.isGranted || s.isLimited) return PermissaoCamera.concedida;
  if (s.isPermanentlyDenied || s.isRestricted) return PermissaoCamera.negada;
  if (s.isDenied) {
    // No Android "denied" também é o estado inicial (nunca perguntado)
    return PermissaoCamera.naoPerguntada;
  }
  return PermissaoCamera.naoPerguntada;
}

Future<bool> pedirPermissaoCamera() async {
  final s = await Permission.camera.request();
  return s.isGranted || s.isLimited;
}

Future<bool> abrirAjustesAparelho() => openAppSettings();

Future<void> initCamera({bool frontal = true}) async {
  if (_inicializando) return;
  final atual = _controle.value;
  final direcao =
      frontal ? CameraLensDirection.front : CameraLensDirection.back;
  if (atual != null &&
      atual.value.isInitialized &&
      atual.description.lensDirection == direcao) {
    return;
  }
  _inicializando = true;
  try {
    if (!(await Permission.camera.request()).isGranted) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final escolhida = cameras.firstWhere(
      (c) => c.lensDirection == direcao,
      orElse: () => cameras.first,
    );
    await pararCamera();
    final c = CameraController(escolhida, ResolutionPreset.medium,
        enableAudio: false);
    await c.initialize();
    _controle.value = c;
  } catch (e) {
    debugPrint('Erro ao abrir a câmera: $e');
  } finally {
    _inicializando = false;
  }
}

Future<void> pararCamera() async {
  final c = _controle.value;
  _controle.value = null;
  await c?.dispose();
}

Widget buildCameraView() {
  return ValueListenableBuilder<CameraController?>(
    valueListenable: _controle,
    builder: (context, c, _) {
      if (c == null || !c.value.isInitialized) return const SizedBox.expand();
      // Preenche a área (como object-fit: cover)
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: c.value.previewSize?.height ?? 1,
            height: c.value.previewSize?.width ?? 1,
            child: CameraPreview(c),
          ),
        ),
      );
    },
  );
}

Future<String?> capturarFrame() async {
  final c = _controle.value;
  if (c == null || !c.value.isInitialized) return null;
  try {
    final img = await c.takePicture();
    final bytes = await img.readAsBytes();
    return base64Encode(bytes);
  } catch (e) {
    debugPrint('Erro ao capturar: $e');
    return null;
  }
}
