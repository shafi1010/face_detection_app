import 'dart:typed_data';

import 'package:flutter/material.dart';

class FacePreviewScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const FacePreviewScreen({Key? key, required this.imageBytes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Preview'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
