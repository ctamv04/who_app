import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'dart:io';

class DrawingPage extends StatefulWidget {
  final Uint8List imageFile;

  const DrawingPage({Key? key, required this.imageFile}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late ImagePainterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController();
  }

  Future<void> saveDrawing() async {
    final editedImage = await _controller.exportImage();
    if (editedImage != null) {
      Navigator.pop(context, editedImage);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw on Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveDrawing,
          ),
        ],
      ),
      body: Center(
        child: ImagePainter.memory(
          widget.imageFile,
          controller: _controller,
          scalable: false,
        )
      ),
    );
  }
}