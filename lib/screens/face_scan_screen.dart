import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/gsi_api_service.dart';
import 'verification_result_screen.dart';

class FaceScanScreen extends StatefulWidget {
  final String docSeria;
  final String docNumber;
  final String birthDate;

  const FaceScanScreen({
    super.key,
    required this.docSeria,
    required this.docNumber,
    required this.birthDate,
  });

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _controller;
  CameraDescription? _cameraDescription;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isSending = false;
  bool _faceDetected = false;
  bool _isProcessingFrame = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  String? _errorMessage;

  late final FaceDetector _faceDetector;

  static const _recordDuration = 5;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.20,
      ),
    );
    _initCamera();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final statuses =
          await [Permission.camera, Permission.microphone].request();
      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        if (mounted) {
          setState(() =>
              _errorMessage = 'Camera and microphone permissions are required.');
        }
        return;
      }
      final cameras = await availableCameras();
      _cameraDescription = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        _cameraDescription!,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Camera error: $e');
      }
    }
  }

  void _startFaceDetection() {
    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessingFrame || _isRecording || _isSending) return;
      _isProcessingFrame = true;
      try {
        final inputImage = _buildInputImage(image);
        if (inputImage == null) return;
        final faces = await _faceDetector.processImage(inputImage);
        final detected = _hasFaceInOval(faces, image);
        if (mounted && detected != _faceDetected) {
          setState(() => _faceDetected = detected);
        }
        if (detected && !_isRecording && mounted) {
          await _controller!.stopImageStream();
          _startRecording();
        }
      } catch (_) {
        // ignore detection errors
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  Future<void> _abortRecording() async {
    if (!_isRecording) return;
    _countdownTimer?.cancel();
    setState(() {
      _isRecording = false;
      _faceDetected = false;
      _countdown = _recordDuration;
    });
    try {
      await _controller!.stopVideoRecording();
    } catch (_) {}
    if (mounted && !_isSending) {
      _startFaceDetection();
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final camera = _cameraDescription;
    if (camera == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Only nv21 (Android) and bgra8888 (iOS) are supported by ML Kit
    if (format != InputImageFormat.nv21 &&
        format != InputImageFormat.bgra8888) {
      return null;
    }

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Returns true if at least one detected face center falls within the oval region.
  bool _hasFaceInOval(List<Face> faces, CameraImage image) {
    if (faces.isEmpty) return false;

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    // Oval defined in the painter (relative to screen size):
    //   center: (0.5, 0.45),  half-w: 0.325,  half-h: 0.21
    // We approximate the same ratios against the image dimensions.
    final ovalCx = imgW * 0.5;
    final ovalCy = imgH * 0.45;
    final ovalHalfW = imgW * 0.33;
    final ovalHalfH = imgH * 0.22;

    for (final face in faces) {
      final bb = face.boundingBox;
      final faceCx = bb.left + bb.width / 2;
      final faceCy = bb.top + bb.height / 2;

      // Normalized distance inside ellipse: value <= 1 means inside
      final dx = (faceCx - ovalCx) / ovalHalfW;
      final dy = (faceCy - ovalCy) / ovalHalfH;
      if (dx * dx + dy * dy <= 1.4) return true; // slight tolerance
    }
    return false;
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
      _faceDetected = true;
      _countdown = _recordDuration;
    });
    try {
      await _controller!.startVideoRecording(
        onAvailable: (CameraImage image) async {
          if (_isProcessingFrame || !_isRecording) return;
          _isProcessingFrame = true;
          try {
            final inputImage = _buildInputImage(image);
            if (inputImage == null) return;
            final faces = await _faceDetector.processImage(inputImage);
            final detected = _hasFaceInOval(faces, image);
            if (mounted && detected != _faceDetected) {
              setState(() => _faceDetected = detected);
            }
            if (!detected && _isRecording && mounted) {
              _abortRecording();
            }
          } catch (_) {
          } finally {
            _isProcessingFrame = false;
          }
        },
      );

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _countdown--);
        if (_countdown <= 0) {
          timer.cancel();
          _stopAndSend();
        }
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Recording error: $e';
      });
    }
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;
    try {
      final videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isSending = true;
      });

      final result = await GsiApiService.verify(
        docSeria: widget.docSeria,
        docNumber: widget.docNumber,
        birthDate: widget.birthDate,
        videoFile: File(videoFile.path),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationResultScreen(response: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _isRecording = false;
      _isSending = false;
      _faceDetected = false;
      _countdown = _recordDuration;
    });
    _startFaceDetection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Face Scan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) return _buildError();
    if (_isSending) return _buildSending();
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Starting camera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    return _buildCamera();
  }

  Widget _buildCamera() {
    final size = MediaQuery.of(context).size;
    // aspectRatio is width/height in sensor (landscape) coords.
    // Compute scale so the preview covers the full portrait screen.
    var scale = _controller!.value.aspectRatio * size.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(_controller!)),
        ),
        _buildFaceOverlay(),
        _buildInstructions(),
        if (_isRecording) _buildCountdown(),
      ],
    );
  }

  Widget _buildFaceOverlay() {
    return CustomPaint(
      painter: _FaceOverlayPainter(faceDetected: _faceDetected),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      top: 32,
      left: 24,
      right: 24,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _isRecording
              ? 'Hold still while recording...'
              : _faceDetected
                  ? 'Face detected! Starting recording...'
                  : 'Position your face inside the oval\nLook straight at the camera',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE4A216),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recording...',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSending() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFE4A216)),
          SizedBox(height: 20),
          Text(
            'Verifying identity...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE4A216),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  final bool faceDetected;
  const _FaceOverlayPainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: size.width * 0.65,
      height: size.height * 0.42,
    );

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    final borderPaint = Paint()
      ..color = faceDetected ? const Color(0xFFE4A216) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceDetected ? 3.5 : 2.5;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(_FaceOverlayPainter old) =>
      old.faceDetected != faceDetected;
}
