import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class Record extends StatefulWidget {
  final String? title;
  final String? script;

  const Record({super.key, this.title, this.script});

  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitializing = false;
  bool _isCameraInitialized = false;
  String? _cameraErrorMessage;

  // Auto-scroll logic
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  Timer? _scrollTimer;
  double _scrollSpeed = 30.0; // pixels per second
  double _fontSize = 28.0;
  double _overlayOpacity = 0.0; // 0.0 (clear unmasked camera), 0.25 (subtle), 0.5 (dark)

  // Recording logic
  bool _isRecording = false;
  bool _isRecordingProcessing = false;
  bool _isSavingVideo = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_hasScript) {
      _initCamera();
    }
  }

  bool get _hasScript =>
      widget.title != null &&
      widget.title!.isNotEmpty &&
      widget.script != null &&
      widget.script!.isNotEmpty;

  @override
  void didUpdateWidget(Record oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasScript &&
        (oldWidget.title != widget.title || oldWidget.script != widget.script)) {
      if (!_isCameraInitialized && !_isCameraInitializing) {
        _initCamera();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopAutoScroll();
      _stopRecordingTimer();

      if (cameraController.value.isRecordingVideo) {
        try {
          final video = await cameraController.stopVideoRecording();
          await Gal.putVideo(video.path);
        } catch (e) {
          debugPrint('Failed to save recording on app pause: $e');
        }
      }

      await cameraController.dispose();
      _cameraController = null;

      if (mounted) {
        setState(() {
          _isRecording = false;
          _isCameraInitialized = false;
          _isRecordingProcessing = false;
          _isSavingVideo = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_hasScript) {
        _initCamera(cameraIndex: _selectedCameraIndex);
      }
    }
  }

  Future<void> _initCamera({int? cameraIndex}) async {
    if (_isCameraInitializing) return;

    setState(() {
      _isCameraInitializing = true;
      _cameraErrorMessage = null;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _cameraErrorMessage = "No camera found on this device.";
          _isCameraInitializing = false;
          _isCameraInitialized = false;
        });
        return;
      }

      int targetIndex = cameraIndex ?? 0;
      if (cameraIndex == null) {
        // Default to front-facing camera for selfie teleprompter mode
        final frontIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (frontIndex != -1) {
          targetIndex = frontIndex;
        }
      }

      _selectedCameraIndex = targetIndex;

      final controller = CameraController(
        _cameras[targetIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      _cameraController = controller;
      await controller.initialize();

      try {
        await controller.setFocusMode(FocusMode.auto);
        await controller.setExposureMode(ExposureMode.auto);
      } catch (e) {
        // Some camera hardware might not support focus/exposure mode configuration
        debugPrint('Focus/Exposure mode configuration warning: $e');
      }

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _isCameraInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraErrorMessage =
            "Unable to access camera. Please verify camera permissions in settings.\n\n($e)";
        _isCameraInitializing = false;
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length <= 1) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;

    await _cameraController?.dispose();
    _cameraController = null;
    setState(() {
      _isCameraInitialized = false;
    });

    await _initCamera(cameraIndex: nextIndex);
  }

  void _toggleOverlayOpacity() {
    setState(() {
      if (_overlayOpacity == 0.0) {
        _overlayOpacity = 0.25;
      } else if (_overlayOpacity == 0.25) {
        _overlayOpacity = 0.50;
      } else {
        _overlayOpacity = 0.0;
      }
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _isScrolling = !_isScrolling;
    });

    if (_isScrolling) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients || !_isScrolling) {
        timer.cancel();
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll >= maxScroll) {
        setState(() {
          _isScrolling = false;
        });
        timer.cancel();
        return;
      }

      final step = _scrollSpeed * 0.05;
      final newOffset = (currentScroll + step).clamp(0.0, maxScroll);
      _scrollController.jumpTo(newOffset);
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    if (_isScrolling) {
      setState(() {
        _isScrolling = false;
      });
    }
  }

  Future<void> _toggleVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isRecordingProcessing) return;

    setState(() {
      _isRecordingProcessing = true;
    });

    try {
      final isCurrentlyRecording = controller.value.isRecordingVideo || _isRecording;

      if (isCurrentlyRecording) {
        // Enforce a brief delay for very short recordings to avoid native camera driver errors
        if (_recordingSeconds == 0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        setState(() {
          _isSavingVideo = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Saving video to Photos...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        XFile? video;
        try {
          video = await controller.stopVideoRecording();
        } catch (e) {
          debugPrint('Error stopping video recording: $e');
        }

        _stopRecordingTimer();
        _stopAutoScroll();

        if (mounted) {
          setState(() {
            _isRecording = false;
          });
        }

        if (video != null) {
          try {
            await Gal.putVideo(video.path);
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Video saved to your Photos!'),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Video recorded, but failed to save to Photos: $e'),
                  duration: const Duration(seconds: 5),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to stop recording cleanly.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        await controller.startVideoRecording();
        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordingSeconds = 0;
          });
          _startRecordingTimer();

          // Auto-start scrolling when recording starts if not already scrolling
          if (!_isScrolling) {
            _toggleAutoScroll();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecordingProcessing = false;
          _isSavingVideo = false;
          if (controller.value.isInitialized) {
            _isRecording = controller.value.isRecordingVideo;
          }
        });
      }
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoScroll();
    _stopRecordingTimer();
    _cameraController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasScript) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create a script to start recording.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera Live Feed Background
            Positioned.fill(
              child: _buildCameraPreview(),
            ),

            // 2. Optional Translucent Overlay for High Contrast Text Readability
            if (_overlayOpacity > 0.0)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: _overlayOpacity),
                ),
              ),

            // 3. Main Content Layer (Header, Script, Controls)
            Column(
              children: [
                // Top Header Bar
                _buildHeaderBar(),

                // Teleprompter Script Scroll Area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 40,
                    ),
                    child: Text(
                      widget.script!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _fontSize,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            color: Colors.black,
                          ),
                          Shadow(
                            offset: Offset(0, 0),
                            blurRadius: 4,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Control Toolbar
                _buildControlToolbar(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitializing) {
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

    if (_cameraErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white70, size: 64),
              const SizedBox(height: 16),
              Text(
                _cameraErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _initCamera(cameraIndex: _selectedCameraIndex),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Camera'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isCameraInitialized && _cameraController != null) {
      final mediaSize = MediaQuery.of(context).size;
      final cameraAspectRatio = _cameraController!.value.aspectRatio;

      var scale = mediaSize.aspectRatio * cameraAspectRatio;
      if (scale < 1) scale = 1 / scale;

      return ClipRect(
        child: SizedBox.expand(
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Script Title
          Expanded(
            child: Text(
              widget.title ?? '',
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Recording Indicator Badge
          if (_isRecording) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Camera Flip Switch Button
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              tooltip: 'Switch Camera',
              onPressed: _toggleCamera,
            ),
        ],
      ),
    );
  }

  Widget _buildControlToolbar() {
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
                onPressed: () {
                  setState(() {
                    if (_fontSize >= 40.0) {
                      _fontSize = 20.0;
                    } else {
                      _fontSize += 4.0;
                    }
                  });
                },
              ),

              // Text Backdrop Contrast Dimmer
              IconButton(
                icon: Icon(
                  _overlayOpacity == 0.0
                      ? Icons.tonality_outlined
                      : _overlayOpacity == 0.25
                          ? Icons.tonality
                          : Icons.brightness_medium,
                  color: _overlayOpacity > 0.0 ? Colors.amber : Colors.white,
                ),
                tooltip:
                    'Text Contrast Overlay (${(_overlayOpacity * 100).toInt()}%)',
                onPressed: _toggleOverlayOpacity,
              ),

              // Scroll Speed Controller
              InkWell(
                onTap: () {
                  setState(() {
                    if (_scrollSpeed >= 70.0) {
                      _scrollSpeed = 15.0;
                    } else {
                      _scrollSpeed += 15.0;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${(_scrollSpeed / 15).toStringAsFixed(0)}x Speed',
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
                  _isScrolling
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 36,
                ),
                tooltip: _isScrolling ? 'Pause Scroll' : 'Start Scroll',
                onPressed: _toggleAutoScroll,
              ),

              // Record Video Shutter Button
              GestureDetector(
                onTap: _isRecordingProcessing ? null : _toggleVideoRecording,
                child: Opacity(
                  opacity: _isRecordingProcessing ? 0.6 : 1.0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: _isSavingVideo
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
                              width: _isRecording ? 18 : 28,
                              height: _isRecording ? 18 : 28,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: _isRecording
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                                borderRadius: _isRecording
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
