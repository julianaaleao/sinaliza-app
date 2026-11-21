// Plataformas sem câmera suportada (ex.: desktop): nada a fazer
import 'package:flutter/material.dart';

enum PermissaoCamera { concedida, negada, naoPerguntada }

Future<PermissaoCamera> permissaoCamera() async => PermissaoCamera.concedida;
Future<bool> pedirPermissaoCamera() async => true;
Future<bool> abrirAjustesAparelho() async => false;
Future<void> initCamera({bool frontal = true}) async {}
Future<void> pararCamera() async {}
Widget buildCameraView() => const SizedBox.expand();
Future<String?> capturarFrame() async => null;
