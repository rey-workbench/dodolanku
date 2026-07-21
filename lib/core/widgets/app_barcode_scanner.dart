import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dodolanku/core/config/app_config.dart';
import 'package:dodolanku/core/services/audio_service.dart';
import 'package:dodolanku/core/widgets/app_scanner_viewfinder.dart';
import 'package:dodolanku/core/services/permission_service.dart';

class AppBarcodeScanner extends StatefulWidget {
  final Function(String barcode) onScan;
  final bool isScanning;

  const AppBarcodeScanner({
    super.key,
    required this.onScan,
    this.isScanning = true,
  });

  @override
  State<AppBarcodeScanner> createState() => _AppBarcodeScannerState();
}

class _AppBarcodeScannerState extends State<AppBarcodeScanner>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  DateTime? _lastScanTime;

  bool _hasPermission = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      cameraResolution: const Size(1280, 720),
      formats: ScannerConfig.scannerFormats,
    );
    WidgetsBinding.instance.addObserver(this);
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final granted = await PermissionService.instance.requestCameraPermission();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _checkingPermission = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_hasPermission) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _checkingPermission
              ? const Center(child: CircularProgressIndicator())
              : !_hasPermission
                  ? Container(
                      color: Colors.black87,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_off, color: Colors.white70, size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Akses Kamera Ditolak',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              onPressed: _requestPermission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Izinkan', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        RepaintBoundary(
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              if (!widget.isScanning) return;

                              // Cooldown 1.5 detik antar scan
                              if (_lastScanTime != null &&
                                  DateTime.now()
                                          .difference(_lastScanTime!)
                                          .inMilliseconds <
                                      1500) {
                                return;
                              }

                              for (final barcode in capture.barcodes) {
                                final rawValue = barcode.rawValue;
                                if (rawValue != null) {
                                  _lastScanTime = DateTime.now();
                                  AudioService.playScanBeep();
                                  widget.onScan(rawValue);
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                        // Dark semi-transparent overlay around the scanner box
                        Container(color: Colors.black.withValues(alpha: 0.4)),
                        const AppScannerViewfinder(),
                      ],
                    ),
        ),
      ),
    );
  }
}
