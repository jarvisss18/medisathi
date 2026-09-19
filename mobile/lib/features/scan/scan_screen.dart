import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'controllers/motion_gate_controller.dart';
import 'controllers/burst_capture_controller.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;

  late final MotionGateController _motionController;
  late final BurstCaptureController _burstController;

  @override
  void initState() {
    super.initState();
    _motionController = MotionGateController();
    _burstController = BurstCaptureController();

    _motionController.addListener(() {
      if (mounted) setState(() {});
    });

    _burstController.addListener(() {
      if (mounted) setState(() {});
    });

    _initializeCamera();
    _motionController.startListening();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasCameraError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasCameraError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    _burstController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _triggerScan() async {
    if (_burstController.isCapturing) return;

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final result = await _burstController.captureBurst(_cameraController!);
      if (result.isComplete && mounted) {
        // Navigate to verification with frame paths
        context.push('/verification', extra: {
          'frames': result.frames.map((f) => f.path).toList(),
          'source': 'camera',
        });
      }
    } else {
      // Demo fallback when running on emulator / desktop without physical camera
      _showDemoImageSelector();
    }
  }

  void _showDemoImageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Test Sample (Demo Fallback)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use simulated strip photos to test end-to-end verification:',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                title: const Text('Paracetamol 500 mg (Clear Match)'),
                subtitle: const Text('Exact match test case'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/verification', extra: {
                    'demo_id': 'TEST-001',
                    'source': 'demo',
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.blur_on, color: Color(0xFFF59E0B)),
                title: const Text('Paracetamol (Blurry / Unclear)'),
                subtitle: const Text('Triggers DON\'T GUESS quality review'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/verification', extra: {
                    'demo_id': 'TEST-002',
                    'source': 'demo',
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFFF59E0B)),
                title: const Text('Amlodipine (Strength Missing)'),
                subtitle: const Text('Look-alike safety ambiguity review'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/verification', extra: {
                    'demo_id': 'TEST-003',
                    'source': 'demo',
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Color(0xFFEF4444)),
                title: const Text('Unknown Brand / Non-Medicine'),
                subtitle: const Text('Triggers REJECT state'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/verification', extra: {
                    'demo_id': 'TEST-004',
                    'source': 'demo',
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Medicine Strip'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, size: 28),
            onPressed: _showDemoImageSelector,
            tooltip: 'Select Test Image / Gallery',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview or Fallback Placeholder
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: const Color(0xFF1E293B),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 80, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(
                      _hasCameraError
                          ? 'Camera unavailable — Use Demo Sample'
                          : 'Initializing camera...',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showDemoImageSelector,
                      icon: const Icon(Icons.image),
                      label: const Text('Choose Demo Sample Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FE8),
                        minimumSize: const Size(220, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // High Contrast Framing Guide & Overlay
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Stability Indicator Bar
                  _buildStabilityMeter(),
                  const SizedBox(height: 16),

                  // Bounding Box Reticle
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _motionController.isSteady
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.black54,
                        child: Text(
                          _motionController.isSteady
                              ? '✓ HOLD STEADY — Ready to Scan'
                              : '⚡ Hold strip still inside frame',
                          style: TextStyle(
                            color: _motionController.isSteady
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Burst Capture Progress Overlay
                  if (_burstController.isCapturing)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Capturing Burst Frames...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _burstController.progress,
                            backgroundColor: Colors.white24,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_burstController.capturedCount} / ${_burstController.totalFrames} frames',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Large Elderly-Friendly Shutter Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _motionController.isSteady
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1E6FE8),
                        minimumSize: const Size(260, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      onPressed: _triggerScan,
                      icon: const Icon(Icons.camera, size: 36),
                      label: const Text(
                        'SCAN MEDICINE',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityMeter() {
    Color statusColor;
    String statusText;

    switch (_motionController.state) {
      case MotionStabilityState.steady:
        statusColor = const Color(0xFF10B981);
        statusText = 'STEADY (Optimal Clarity)';
        break;
      case MotionStabilityState.slightMotion:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'SLIGHT MOTION';
        break;
      case MotionStabilityState.shaking:
        statusColor = const Color(0xFFEF4444);
        statusText = 'HOLD STILL';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 6,
            backgroundColor: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
