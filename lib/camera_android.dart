import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';

CameraController? _ctrl;

Future<void> initCamera() async {
  final cameras = await availableCameras();
  if (cameras.isEmpty) return;
  _ctrl = CameraController(cameras.first, ResolutionPreset.medium);
  await _ctrl!.initialize();
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
    _init();
  }

  Future<void> _init() async {
    await initCamera();
    if (mounted) setState(() {});
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