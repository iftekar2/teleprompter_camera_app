import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:teleprompter_camera_app/components/record/record_components.dart';

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
  double _overlayOpacity =
      0.0; // 0.0 (clear unmasked camera), 0.25 (subtle), 0.5 (dark)

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
        (oldWidget.title != widget.title ||
            oldWidget.script != widget.script)) {
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

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopAutoScroll();
      _stopRecordingTimer();

      if (cameraController.value.isRecordingVideo) {
        try {
          final video = await cameraController.stopVideoRecording();
          await Gal.putVideo(video.path);
        } catch (e) {
          debugPrint('Failed to save recording on app pause.');
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
        debugPrint('Focus/Exposure mode configuration warning');
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
            "Unable to access camera. Please verify camera permissions in settings";
        _isCameraInitializing = false;
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length <= 1 || _isCameraInitializing || _isRecordingProcessing) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;

    final controller = _cameraController;
    final isRecordingActive =
        _isRecording || (controller != null && controller.value.isRecordingVideo);

    if (isRecordingActive && controller != null) {
      setState(() {
        _isRecordingProcessing = true;
      });

      // 1. Enforce delay for 0-second recordings to prevent driver issue
      if (_recordingSeconds == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 2. Stop the current camera's recording segment
      XFile? videoSegment;
      try {
        videoSegment = await controller.stopVideoRecording();
      } catch (e) {
        debugPrint('Error stopping video segment during camera flip: $e');
      }

      // 3. Save completed video segment to Photos
      if (videoSegment != null) {
        try {
          await Gal.putVideo(videoSegment.path);
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📸 Video clip saved to Photos! Switching camera...'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.black87,
              ),
            );
          }
        } catch (e) {
          debugPrint('Failed to save video segment to Photos: $e');
        }
      }

      // 4. Dispose current camera controller
      await controller.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }

      // 5. Initialize the flipped camera
      await _initCamera(cameraIndex: nextIndex);

      // 6. Resume video recording on the new camera
      final newController = _cameraController;
      if (newController != null && newController.value.isInitialized) {
        try {
          await newController.startVideoRecording();
          if (mounted) {
            setState(() {
              _isRecording = true;
              _isRecordingProcessing = false;
            });
          }
        } catch (e) {
          debugPrint('Error starting video recording on flipped camera: $e');
          _stopRecordingTimer();
          _stopAutoScroll();
          if (mounted) {
            setState(() {
              _isRecording = false;
              _isRecordingProcessing = false;
            });
          }
        }
      } else {
        _stopRecordingTimer();
        _stopAutoScroll();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _isRecordingProcessing = false;
          });
        }
      }
    } else {
      await controller?.dispose();
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
      });

      await _initCamera(cameraIndex: nextIndex);
    }
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

  void _toggleFontSize() {
    setState(() {
      if (_fontSize >= 40.0) {
        _fontSize = 20.0;
      } else {
        _fontSize += 4.0;
      }
    });
  }

  void _toggleScrollSpeed() {
    setState(() {
      if (_scrollSpeed >= 70.0) {
        _scrollSpeed = 15.0;
      } else {
        _scrollSpeed += 15.0;
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
    if (controller == null ||
        !controller.value.isInitialized ||
        _isRecordingProcessing) {
      return;
    }

    setState(() {
      _isRecordingProcessing = true;
    });

    try {
      final isCurrentlyRecording =
          controller.value.isRecordingVideo || _isRecording;

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
          debugPrint('Error stopping video recording.');
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
                SnackBar(
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "lib/components/image/successfull.jpg",
                        height: 150,
                        width: 150,
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        "Successful",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        "Your video is successfully saved in your phone!",
                        style: TextStyle(color: Colors.black, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.white,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                // SnackBar(
                //   content: Text(
                //     'Video recorded, but failed to save to Photos: $e',
                //   ),
                //   duration: const Duration(seconds: 5),
                //   backgroundColor: Colors.orange,
                // ),
                SnackBar(
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "ib/components/image/failed-to-save.png",
                        height: 150,
                        width: 150,
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        "Failed to Save",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'Video recorded, but failed to save to Photos',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.white,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start recording.')));
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
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,

                  child: Image.asset(
                    'lib/components/image/welcome-page-image.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontSize: 22),
                    ),

                    SizedBox(width: 7),
                    Text(
                      "PaceCam",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                Text(
                  "You don't have any script yet. Create a script to start recording here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 20),
                ),

                // SizedBox(height: 20),
                // ElevatedButton(onPressed: () {}, child: Text("Create Script")),
              ],
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
              child: CameraPreviewView(
                controller: _cameraController,
                isInitializing: _isCameraInitializing,
                isInitialized: _isCameraInitialized,
                errorMessage: _cameraErrorMessage,
                onRetry: () => _initCamera(cameraIndex: _selectedCameraIndex),
              ),
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
                RecordHeader(
                  title: widget.title ?? '',
                  isRecording: _isRecording,
                  isRecordingProcessing: _isRecordingProcessing,
                  recordingSeconds: _recordingSeconds,
                  formattedDuration: _formatDuration(_recordingSeconds),
                  cameraCount: _cameras.length,
                  onToggleCamera: _toggleCamera,
                ),

                // Teleprompter Script Scroll Area
                TeleprompterText(
                  scrollController: _scrollController,
                  script: widget.script!,
                  fontSize: _fontSize,
                ),

                // Bottom Control Toolbar
                RecordControls(
                  fontSize: _fontSize,
                  overlayOpacity: _overlayOpacity,
                  scrollSpeed: _scrollSpeed,
                  isScrolling: _isScrolling,
                  isRecording: _isRecording,
                  isRecordingProcessing: _isRecordingProcessing,
                  isSavingVideo: _isSavingVideo,
                  onToggleFontSize: _toggleFontSize,
                  onToggleOverlayOpacity: _toggleOverlayOpacity,
                  onToggleScrollSpeed: _toggleScrollSpeed,
                  onToggleAutoScroll: _toggleAutoScroll,
                  onToggleVideoRecording: _toggleVideoRecording,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
