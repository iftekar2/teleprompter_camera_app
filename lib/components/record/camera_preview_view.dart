import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewView extends StatelessWidget {
  final CameraController? controller;
  final bool isInitializing;
  final bool isInitialized;
  final String? errorMessage;
  final VoidCallback onRetry;

  const CameraPreviewView({
    super.key,
    required this.controller,
    required this.isInitializing,
    required this.isInitialized,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Starting camera...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white70, size: 64),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Camera'),
              ),
            ],
          ),
        ),
      );
    }

    if (isInitialized && controller != null) {
      final mediaSize = MediaQuery.of(context).size;
      final cameraAspectRatio = controller!.value.aspectRatio;

      var scale = mediaSize.aspectRatio * cameraAspectRatio;
      if (scale < 1) scale = 1 / scale;

      return ClipRect(
        child: SizedBox.expand(
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(controller!),
            ),
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}
