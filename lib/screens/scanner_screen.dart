import 'package:flutter/material.dart';
import 'package:flutter_mrz_scanner/flutter_mrz_scanner.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MRZController? _controller;
  bool _flashOn = false;
  bool _navigating = false;

  @override
  void dispose() {
    _controller?.stopPreview();
    super.dispose();
  }

  void _onControllerCreated(MRZController controller) {
    _controller = controller;
    controller.onError = (error) {
      debugPrint('MRZ error: $error');
    };
    controller.onParsed = (MRZResult result) {
      if (_navigating) return;
      _navigating = true;
      _controller?.stopPreview();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
    };
    controller.startPreview();
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _flashOn ? _controller?.flashlightOn() : _controller?.flashlightOff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _controller != null ? _toggleFlash : null,
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            color: _flashOn ? Colors.yellow : Colors.white,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MRZScanner(
            withOverlay: true,
            onControllerCreated: _onControllerCreated,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Point camera at MRZ lines on document',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
