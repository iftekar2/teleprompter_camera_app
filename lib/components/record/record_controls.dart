import 'package:flutter/material.dart';

class RecordControls extends StatelessWidget {
  final double fontSize;
  final double overlayOpacity;
  final double scrollSpeed;
  final bool isScrolling;
  final bool isRecording;
  final bool isRecordingProcessing;
  final bool isSavingVideo;
  final VoidCallback onToggleFontSize;
  final VoidCallback onToggleOverlayOpacity;
  final VoidCallback onToggleScrollSpeed;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onToggleVideoRecording;

  const RecordControls({
    super.key,
    required this.fontSize,
    required this.overlayOpacity,
    required this.scrollSpeed,
    required this.isScrolling,
    required this.isRecording,
    required this.isRecordingProcessing,
    required this.isSavingVideo,
    required this.onToggleFontSize,
    required this.onToggleOverlayOpacity,
    required this.onToggleScrollSpeed,
    required this.onToggleAutoScroll,
    required this.onToggleVideoRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: const Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Font Size Adjustment
              IconButton(
                icon: const Icon(Icons.format_size, color: Colors.white),
                tooltip: 'Font Size',
                onPressed: onToggleFontSize,
              ),

              // Text Backdrop Contrast Dimmer
              IconButton(
                icon: Icon(
                  overlayOpacity == 0.0
                      ? Icons.tonality_outlined
                      : overlayOpacity == 0.25
                          ? Icons.tonality
                          : Icons.brightness_medium,
                  color: overlayOpacity > 0.0 ? Colors.amber : Colors.white,
                ),
                tooltip:
                    'Text Contrast Overlay (${(overlayOpacity * 100).toInt()}%)',
                onPressed: onToggleOverlayOpacity,
              ),

              // Scroll Speed Controller
              InkWell(
                onTap: onToggleScrollSpeed,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${(scrollSpeed / 15).toStringAsFixed(0)}x Speed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Play / Pause Auto-Scroll Button
              IconButton(
                icon: Icon(
                  isScrolling
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 36,
                ),
                tooltip: isScrolling ? 'Pause Scroll' : 'Start Scroll',
                onPressed: onToggleAutoScroll,
              ),

              // Record Video Shutter Button
              GestureDetector(
                onTap: isRecordingProcessing ? null : onToggleVideoRecording,
                child: Opacity(
                  opacity: isRecordingProcessing ? 0.6 : 1.0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: isSavingVideo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isRecording ? 18 : 28,
                              height: isRecording ? 18 : 28,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: isRecording
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                                borderRadius: isRecording
                                    ? BorderRadius.circular(4)
                                    : null,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
