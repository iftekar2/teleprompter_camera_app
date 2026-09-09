import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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

  // Recording logic
  bool _isRecording = false;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopAutoScroll();
      _stopRecordingTimer();
      cameraController.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
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
    if (controller == null || !controller.value.isInitialized) return;

    if (_isRecording) {
      try {
        final video = await controller.stopVideoRecording();
        _stopRecordingTimer();
        setState(() {
          _isRecording = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved: ${video.name}'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to stop recording: $e')),
          );
        }
      }
    } else {
      try {
        await controller.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
        _startRecordingTimer();

        // Also auto-start scrolling when recording starts if not already scrolling
        if (!_isScrolling) {
          _toggleAutoScroll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start recording: $e')),
          );
        }
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

            // 2. Translucent Overlay for High Contrast Text Readability
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
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
                            blurRadius: 6,
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
      return ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 100,
              height: _cameraController!.value.previewSize?.width ?? 100,
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
                onTap: _toggleVideoRecording,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: AnimatedContainer(
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
            ],
          ),
        ],
      ),
    );
  }
}
