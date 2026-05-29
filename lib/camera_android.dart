import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

CameraController? _ctrl;
bool _inicializando = false;

Future<void> initCamera() async {
  if (_ctrl != null && _ctrl!.value.isInitialized) return;
  if (_inicializando) return;
  _inicializando = true;

  final status = await Permission.camera.request();
  if (!status.isGranted) {
    _inicializando = false;
    return;
  }

  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    _inicializando = false;
    return;
  }

  _ctrl = CameraController(cameras.first, ResolutionPreset.medium);
  await _ctrl!.initialize();
  _inicializando = false;
}

Widget buildCameraView() {
  return const _AndroidCameraView();
}

class _AndroidCameraView extends StatefulWidget {
  const _AndroidCameraView();

  @override
  State<_AndroidCameraView> createState() => _AndroidCameraViewState();
}

class _AndroidCameraViewState extends State<_AndroidCameraView> {
  @override
  void initState() {
    super.initState();
    _esperar(); // só espera, não chama initCamera() de novo
  }

  Future<void> _esperar() async {
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_ctrl != null && _ctrl!.value.isInitialized) {
        if (mounted) setState(() {});
        return;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _ctrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_ctrl!);
  }
}

Future<String?> capturarFrame(dynamic a, dynamic b) async {
  if (_ctrl == null || !_ctrl!.value.isInitialized) return null;
  final img = await _ctrl!.takePicture();
  final bytes = await img.readAsBytes();
  return base64Encode(bytes);
}