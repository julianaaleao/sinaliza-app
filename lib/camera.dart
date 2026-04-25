import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  String _resultado = '...';
  bool _ativo = false;
  html.VideoElement? _video;

  @override
  void initState() {
    super.initState();
    _configurarCamera();
  }

  void _configurarCamera() {
    _video = html.VideoElement()
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': false}).then((stream) {
      _video!.srcObject = stream;
    });

    ui.platformViewRegistry.registerViewFactory(
      'camera-view',
      (int viewId) => _video!,
    );
  }

  void _toggleCamera() {
    setState(() {
      _ativo = !_ativo;
      if (_ativo) {
        _resultado = '...';
      } else {
        _resultado = '...';
      }
    });
  }

  @override
  void dispose() {
    _video?.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SINALIZA'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/historico'),
            icon: Icon(Icons.history),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/login'),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: HtmlElementView(viewType: 'camera-view'),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            color: Colors.deepPurple.shade50,
            child: Column(
              children: [
                Text(
                  _resultado,
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  _ativo ? 'Detectando...' : 'Câmera pausada',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _toggleCamera,
              icon: Icon(_ativo ? Icons.stop : Icons.play_arrow),
              label: Text(_ativo ? 'Parar' : 'Iniciar reconhecimento'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 54),
                backgroundColor: _ativo ? Colors.red : Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}